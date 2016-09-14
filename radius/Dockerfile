FROM centos:7

MAINTAINER Nikos Mavrogiannopoulos <nmav@redhat.com>

RUN yum install -y epel-release
RUN yum install -y nuttcp ocserv iptables iperf freeradius radcli

COPY ocserv.conf /etc/ocserv/ocserv.conf
COPY radcli.conf /etc/radcli/rad-ocserv.conf
COPY servers /etc/radcli/
COPY dictionary /etc/radcli/
COPY freeradius-users /etc/raddb/users
COPY freeradius-clients.conf /etc/raddb/clients.conf

WORKDIR /etc/ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
EXPOSE 443/UDP
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f", "-d", "3"]

