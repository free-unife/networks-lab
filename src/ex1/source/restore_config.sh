#!/bin/bash

#
# restore_config.conf
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
# Restore Openldap server configuration.
#

# Some variables
suffix="dc=gruppo2,dc=labreti,dc=it"
rootdn="cn=root,dc=gruppo2,dc=labreti,dc=it"
slapdconf="/etc/openldap/slapd.conf"
ldapconf="/etc/openldap/ldap.conf"
schemasDir="/etc/openldap/schema"
ret=""

ldapRootPwd="gruppo2"


# Check if root is running this script.
if [ "$UID" -ne 0 ]; then
	echo -e -n "You must be root tu run this script.\n"
	echo -e -n "sudo -u root $0\n"
	exit 1
fi

echo -en "Restore configuration started...\n"

systemctl start slapd

# Wipe previous entries
# Only for Arch Linux and maybe other systems with systemd.
systemctl stop slapd
systemctl disable slapd

echo -en "Removing old database... "
# Remove database.
rm -rf /var/lib/openldap/openldap-data/*
echo -en "[DONE]\n"

echo -e -n "Adding new configuration in slapd.conf file... "
# Delete previous configuration.
# sed -i "... d" "$slapdcond"
sed -i "/suffix\|rootdn\|rootpw\|cosine.schema\|inetorgperson.schema\|nis.schema\|dnszone.schema\|misc.schema/ d" "$slapdconf"
# Write config to file.
echo "suffix     \"$suffix\"" >> "$slapdconf"
echo "rootdn     \"$rootdn\"" >> "$slapdconf"
echo -en "rootpw\t$(slappasswd -s "$ldapRootPwd")\n" >> "$slapdconf"
echo -en "\
include\t/etc/openldap/schema/cosine.schema\n\
include\t/etc/openldap/schema/inetorgperson.schema\n\
include\t/etc/openldap/schema/nis.schema\n\
include\t/etc/openldap/schema/dnszone.schema\n\
include\t/etc/openldap/schema/misc.schema\n" >> "$slapdconf"

# Delete previous configuration.
sed -i "/index/ d" "$slapdconf"
# Write config to file.
echo -e -n "\
index   uid             pres,eq\n\
index   mail            pres,sub,eq\n\
index   cn              pres,sub,eq\n\
index   sn              pres,sub,eq\n\
index   dc              eq\n\
index   relativeDomainName              eq\n\
index   zoneName        eq\n" >> "$slapdconf"

# Delete previous configuration.
sed -i "/access\|by/ d" "$slapdconf"
# Write config to file.
echo -e -n "\
access to attrs=userPassword,telephoneNumber\n\
\tby self write\n\
\tby anonymous auth\n\
\tby dn.base=\""$rootdn"\" write\n\
\tby * none\n\
access to *\n\
\tby self write\n\
\tby dn.base=\""$rootdn\"" write\n\
\tby * read\n\n" >> "$slapdconf"
echo -en "[DONE]\n"

# Copy user defined schema (to be used for DNS data).
cat "dnszone.schema" > "$schemasDir"/dnszone.schema

# Write to client config file.
echo -e -n "\
BASE		"$suffix"\n\
URI		ldap://localhost\n\
TLS_REQCERT	allow\n" > "$ldapconf"

# Copy example db.
cp /etc/openldap/DB_CONFIG.example \
	/var/lib/openldap/openldap-data/DB_CONFIG
chown ldap:ldap /var/lib/openldap/openldap-data/DB_CONFIG

rm -rf /etc/openldap/slapd.d/*

# Remove old config.
# Create db.
systemctl start slapd
systemctl stop slapd

echo -en "Checking slapd.conf file. Fatal errors will be \
reported... "
slaptest -f "$slapdconf" -F /etc/openldap/slapd.d/
echo -en "[DONE]\n"

chown -R ldap:ldap /etc/openldap/slapd.d
slapindex
chown ldap:ldap /var/lib/openldap/openldap-data/*

# Start ldap daemon.
systemctl enable slapd

echo -en "Starting slapd.service... "
systemctl start slapd
ret="$?"
if [ "$ret" -gt 0 ]; then
	echo -en "[FAILED] Restore configuration.\n\n"
	exit 1
fi

echo -en "[DONE]\n"

echo -en "[OK] Restore configuration."

exit 0
