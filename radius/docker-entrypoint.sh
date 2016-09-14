#!/bin/sh

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$RADIUS_SERVER_NAME" ]; then
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
	cn = "${RADIUS_SERVER_NAME}"
	expiration_days = 9999
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
fi

if test -n "$RADIUS_TESTUSER1";then
	echo "${RADIUS_TESTUSER1} 	Cleartext-Password := \"${RADIUS_TESTPASS1}\"" >> /etc/raddb/users
	echo "	Service-Type = Framed-User," >> /etc/raddb/users
	echo "	Framed-Protocol = PPP," >> /etc/raddb/users
	test -z $RADIUS_TESTUSER1_NET || echo "	Framed-Route = $RADIUS_TESTUSER1_NET," >> /etc/raddb/users
	test -z $RADIUS_TESTUSER1_IP || echo "	Framed-IP-Address = $RADIUS_TESTUSER1_IP," >> /etc/raddb/users 
	echo "	Framed-IP-Netmask = 255.255.255.0," >> /etc/raddb/users
	test -z $RADIUS_TESTUSER1_GROUP || echo "	Class = \"$RADIUS_TESTUSER1_GROUP\"," >> /etc/raddb/users
	echo "	Framed-MTU = 1500" >> /etc/raddb/users
	echo "" >> /etc/raddb/users

	sed -i 's|%NETWORK|'$RADIUS_TESTUSER1_NET'|g' /etc/ocserv/ocserv.conf
else
	sed -i 's|%NETWORK|'$RADIUS_NET'|g' /etc/ocserv/ocserv.conf
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

#run nuttcp
if test -x /usr/bin/nuttcp;then
nuttcp -S
fi
iperf -s &

echo "Creating TUN device"
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

radiusd

# Run OpennConnect Server
exec "$@"
