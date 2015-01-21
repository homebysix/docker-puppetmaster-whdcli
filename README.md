# docker-puppetmaster-whdcli
Copy of Puppetmaster, except with [WHD-CLI](https://github.com/nmcspadden/WHD-CLI) installed.

This Docker container is based on CentOS 6 and installs the Puppet master along with [WHD-CLI](https://github.com/nmcspadden/WHD-CLI).

This container sets the autosign policy to check_csr.py, which looks up the serial number in WebHelpDesk.  If the serial number is found, it autosigns the Puppet certificate request.

This container is designed to be used with a data-only container, and thus all data is kept in /opt/puppet/ and /opt/varpuppet/lib/puppet/.

To use this container:
====

1.	First, run a [WebHelpDesk](https://registry.hub.docker.com/u/macadmins/whd/) Docker container with `--name whd`.

2.	You'll need to use WebHelpDesk to [generate an API key](http://www.solarwinds.com/documentation/webhelpdesk/docs/whd_api_12.1.0/web%20help%20desk%20api.html#auth-tech-api-key) first for an account with permissions to read and edit all assets.

3.	Copy and paste that API key into com.github.nmcspadden.whd-cli.plist. You can obtain the plist easily with curl:  
	`curl -O https://raw.githubusercontent.com/macadmins/puppetmaster-whdcli/master/com.github.nmcspadden.whd-cli.plist`
4.	For this example, I'm storing it on the Docker host in /home/nmcspadden/com.github.nmcspadden.whd-cli.plist.  You can also fork this repo and the Dockerfile and build your own image with a pre-configured plist.
5.	Create a data-only container to store all Puppet dynamic and fixed data:  
	`docker run -d --name puppet-data --entrypoint /bin/echo macadmins/puppetmaster-whdcli Data-only container for puppetmaster`  
	This data-only container allows you to spin up & down and destroy the puppetmaster containers freely, with no loss of certificate data - all of that is stored inside puppet-data instead, which doesn't take up any system resources because it's not a running container.


To use with WHD container linking (preferred):
-----
1.	The port for the whd_url key in the com.github.nmcspadden.whd-cli.plist must match that of the port WHD is using.  By default, it's 8081.  If you configure it with SSL, it's most likely using 8443.  If you use the name "whd", the URL for linking is http://whd:8081/.
1.	`docker run -d --name puppetmaster -h puppet -p 8140:8140 --volumes-from puppet-data --link whd:whd -v /home/nmcspadden/com.github.nmcspadden.whd-cli.plist:/home/whdcli/com.github.nmcspadden.whd-cli.plist macadmins/puppetmaster-whdcli`
2.	**Critical step:**
	`docker exec puppetmaster cp -Rf /etc/puppet /opt/`  
	**This step is necessary to populate /opt/puppet with all the correct directory structure for puppet to use.  Because of the data-only container, this will not populate itself!**
3.	You should be able to ping whd from within the Docker container:  
	`docker exec puppetmaster ping whd`
4.	See the section below to test the WHD-CLI hook.
4.	`docker exec puppetmaster puppet cert list -all` to list all existing certs (only the default puppet cert should exist at startup).
5.	To test on a client:
	1.	Install Puppet, Hiera, Facter, Facter-MacFacts (for OS X), and PuppetLaunchD on client.
	2.	Install the [CSR attributes](https://github.com/nmcspadden/Puppet-CSRAttributes) on client. *Without the CSR attributes, the serial number will not be checked and the certs will be autorejected!*
	3.	Add the Docker host IP to /etc/hosts as "puppet".
	4.	`sudo puppet resource service com.puppetlabs.puppet ensure=running enable=true`
	5. 	As root, `# puppet agent --test` to generate the cert request.
	6.	If the client's serial number exists as an asset in WebHelpDesk (and is not deleted), then the cert request should be autosigned.
6.	Use `docker logs puppetmaster` to see the logs of the certificate request.
7.	You can check for more output from the script in /var/log/check_csr.out: `docker exec puppetmaster tail -n 500 /var/log/check_csr.out`
8.	If you want more logging detail, you can set the log level in /etc/puppet/check_csr.py to DEBUG instead of INFO on line 10.

To use this image with direct HTTP/HTTPS:
----


1.	Change com.github.nmcspadden.whd-cli.plist's whd_url key to the web address of your WebHelpDesk instance.  For example: "https://webhelpdesk.domain.org:8443" or "http://webhelpdesk.domain.com:8081"
2.	Run the container with this command:  
	`docker run -d --name puppetmaster -h puppet -p 8140:8140 -v /home/nmcspadden/com.github.nmcspadden.whd-cli.plist:/home/whdcli/com.github.nmcspadden.whd-cli.plist --volumes-from puppet-data macadmins/puppetmaster-whdcli`
	
Testing the WHD-CLI link:
------
1. Run the container either with linking or direct as above.
2. Run Python:  
	`docker exec -it puppetmaster /usr/bin/python`
3. In Python:  
	1.	`>>> import whdcli`
	2.	`>>> whd_prefs = whdcli.WHDPrefs("/home/whdcli/com.github.nmcspadden.whd-cli.plist")`
	3.	`>>> w = whdcli.WHD(whd_prefs)`
	4.	If you get a traceback here, it'll tell you the reason why it failed (such as a bad address, bad API key, or other HTTP authentication failure).
	5.	If it doesn't fail here, you can try to do a serial number lookup:  
		`>>> w.getAssetBySerial("serial")`