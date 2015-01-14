FROM centos:centos6

MAINTAINER nmcspadden@gmail.com

ENV PUPPET_VERSION 3.7.3

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs && rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
RUN yum install -y yum-utils && yum-config-manager --enable centosplus >& /dev/null
RUN yum install -y puppet-$PUPPET_VERSION
RUN yum install -y puppet-server-$PUPPET_VERSION
RUN yum install -y git
RUN yum install -y python-setuptools
RUN yum clean all
RUN git clone git://github.com/kennethreitz/requests.git /home/requests
WORKDIR /home/requests
RUN python /home/requests/setup.py install
RUN git clone https://github.com/nmcspadden/WHD-CLI.git /home/whdcli
WORKDIR /home/whdcli
RUN python /home/whdcli/setup.py install
ADD puppet.conf /etc/puppet/puppet.conf
ADD com.github.nmcspadden.whd-cli.plist /home/whdcli/com.github.nmcspadden.whd-cli.plist
ADD check_csr.py /etc/puppet/check_csr.py
RUN touch /var/log/check_csr.out
RUN chown puppet:puppet /var/log/check_csr.out

EXPOSE 8140

ENTRYPOINT [ "/usr/bin/puppet", "master", "--no-daemonize", "--verbose" ]
