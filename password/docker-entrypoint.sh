#!/bin/sh

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$PASSWORD_SERVER_NAME" ]; then
		SRV_CN="www.example.com"
	fi

	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "Test CA"
	serial = 1
	expiration_days = 9999
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem 
	cat > server.tmpl <<-EOSRV
	cn = "$PASSWORD_SERVER_NAME"
	expiration_days = 9999
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

test -z "$PASSWORD_TESTUSER1" || echo $PASSWORD_TESTPASS1|ocpasswd $PASSWORD_TESTUSER1
test -z "$PASSWORD_TESTUSER2" || echo $PASSWORD_TESTPASS2|ocpasswd $PASSWORD_TESTUSER2
test -z "$PASSWORD_TESTUSER3" || echo $PASSWORD_TESTPASS3|ocpasswd $PASSWORD_TESTUSER3

#run nuttcp
if test -x /usr/bin/nuttcp;then
nuttcp -S
fi
iperf -s &

# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"
