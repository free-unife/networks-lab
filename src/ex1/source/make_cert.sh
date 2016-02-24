#!/bin/bash

#
# make_cert.sh
#
# Copyright (C) 2016 frnmst (Franco Masotti) <franco.masotti@student.unife.it>
#                    dannylessio (Danny Lessio)
#
# This file is part of networks-lab.
#
# networks-lab is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# networks-lab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with networks-lab.  If not, see <http://www.gnu.org/licenses/>.
#


#
# Create ssl certificate and enable it in the server.
#

# Define some variables.
sslCertPath="/etc/openldap/ssl"
slapdconf="/etc/openldap/slapd.conf"


# Check if root is running this script.
if [ "$UID" -ne 0 ]; then
	echo -en "You must be root tu run this script\n"
	echo -en "sudo -u root $0\n"
	exit 1
fi

echo -en "SSL/TLS Openldap configuration started.\n"
systemctl stop slapd

echo -en "Creating SSL/TLS Openldap certificate... "


# Read certificate configuration.
OPENSSLCONFIG=${OPENSSLCONFIG- certificate.conf}

# Create cretificate whick lasts 3650 days.
openssl req -config $OPENSSLCONFIG -new -x509 -nodes -out slapdcert.pem \
	-keyout slapdkey.pem -days 3650
#openssl req -new -x509 -nodes -out slapdcert.pem -keyout slapdkey.pem -days \
#	3650
echo -en "[DONE]\n"

echo -en "Removing previous certificate configuration..."
# Remove previous ssl and create it in openldap.
if [ -d "$sslCertPath" ]; then
	rm -rf "$sslCertPath"
fi
mkdir -p "$sslCertPath"
echo -en "[DONE]\n"

echo -en "Moving certificate to $sslCertPath... "
# Move private and public key in ssl directory
mv slapdcert.pem slapdkey.pem "$sslCertPath/"

# Change permissions to files
chmod -R 755 "$sslCertPath/"
chmod 400 "$sslCertPath/slapdkey.pem"
chmod 444 "$sslCertPath/slapdcert.pem"
chown ldap "$sslCertPath/slapdkey.pem"
echo -en "[DONE]\n"

echo -en "Adding new certificate information... "
# Delete previous certificate info
sed -i "/Certificate\|TLS/ d" /etc/openldap/slapd.conf
# Write certificate info on slapd.conf
echo -e -n "# Certificate/SSL Section\nTLSCipherSuite \
		HIGH:MEDIUM:-SSLv2:-SSLv3\nTLSCertificateFile \
		$sslCertPath/slapdcert.pem\nTLSCertificateKeyFile \
		$sslCertPath/slapdkey.pem\n" >> "$slapdconf"
echo -en "[DONE]\n"

echo -e -n "Adding new systemd configuration... "
if [ ! -f "/etc/systemd/system/slapd.service" ]; then
	cp /usr/lib/systemd/system/slapd.service \
		/etc/systemd/system/slapd.service
fi
# Delete previous configuration.
sed -i "/Service\|Type\|ExecStart/ d" /etc/systemd/system/slapd.service
# Write new config
echo -e -n "\n\
[Service]\n\
Type=forking\n\
ExecStart=/usr/bin/slapd -u ldap -g ldap -h \"ldap:/// ldaps:///\"\n" >> \
	/etc/systemd/system/slapd.service

echo -en "[DONE]\n"

systemctl daemon-reload
systemctl start slapd

# Reset server configuration.
./restore_config.sh

echo -en "Remember to edit ldap.conf on the clients by adding:\nTSL_REQCERT \
\tallow\notherwise it will not be able to connect to this server.\n"
echo -en "[MAYBE OK] SSL/TLS Openldap configuration.\n"

exit 0
