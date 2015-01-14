FROM nmcspadden/puppetmaster:latest

MAINTAINER nmcspadden@gmail.com

RUN yum install -y git
RUN yum install -y python-setuptools
RUN yum clean all
RUN git clone git://github.com/kennethreitz/requests.git /home/requests
WORKDIR /home/requests
RUN python /home/requests/setup.py install
RUN git clone https://github.com/nmcspadden/WHD-CLI.git /home/whdcli
WORKDIR /home/whdcli
RUN python /home/whdcli/setup.py install
ADD com.github.nmcspadden.whd-cli.plist /home/whdcli/com.github.nmcspadden.whd-cli.plist
ADD check_csr.py /etc/puppet/check_csr.py

VOLUME ["/opt/puppet"]

EXPOSE 8140

ENTRYPOINT [ "/usr/bin/puppet", "master", "--no-daemonize", "--verbose" ]
