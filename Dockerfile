FROM centos:7

MAINTAINER Nikos Mavrogiannopoulos <nmav@redhat.com>

RUN yum install -y epel-release
RUN yum install -y nuttcp ocserv iptables iperf

COPY ocserv.conf /etc/ocserv/ocserv.conf

WORKDIR /etc/ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
EXPOSE 443/UDP
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f", "-d", "3"]

