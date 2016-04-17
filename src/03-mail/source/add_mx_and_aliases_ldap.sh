#!/bin/bash

#
# add_mx_and_aliases_ldap.sh
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


# SCRIPT + REVERSE {IPv4,IPv6} ENTRIES.

ldapRootPwd="gruppo2"


echo -en "\
# Name server.\n\
dn: \
relativeDomainName=mail,zoneName=gruppo2.labreti.it,ou=HOST,dc=gruppo2,dc=labreti,dc=it\n\
objectClass: dNSZone\n\
relativeDomainName: mail\n\
zoneName: gruppo2.labreti.it\n\
dNSTTL: 86400\n\
dNSClass: MX\n\
aRecord: 192.168.2.10\n\
aAAARecord: 2002:0000:0000:0000:0000:0000:0000:000a\n\n\
# Reverse mx entries.\n\n\
# ALIAS, gruppo2.labreti.it\n\
dn: ou=ALIAS,dc=gruppo2,dc=labreti,dc=it\n\
ou: ALIAS\n\
objectClass: organizationalUnit\n\n\
# Mail aliases.\n\
dn: cn=franco.masotti,ou=ALIAS,dc=gruppo2,dc=labreti,dc=it\n\
objectClass: top\n\
objectClass: nisMailAlias\n\
cn: franco.masotti\n\
rfc822MailMember: francomasotti\n\n\
dn: cn=danny.lessio,ou=ALIAS,dc=gruppo2,dc=labreti,dc=it\n\
objectClass: top\n\
objectClass: nisMailAlias\n\
cn: danny.lessio\n\
rfc822MailMember: dannylessio\n\n\
dn: cn=jack.tripper,ou=ALIAS,dc=gruppo2,dc=labreti,dc=it\n\
objectClass: top\n\
objectClass: nisMailAlias\n\
cn: jack.tripper\n\
rfc822MailMember: jacktripper\n\n\
dn: cn=janet.wood,ou=ALIAS,dc=gruppo2,dc=labreti,dc=it\n\
objectClass: top\n\
objectClass: nisMailAlias\n\
cn: janet.wood\n\
rfc822MailMember: janetwood\n\
" > "gruppo2.labreti.it.aliases.ldif"

sudo ldapadd -H ldap://192.168.2.10 -x -w "$ldapRootPwd" -D \
	"cn=root,dc=gruppo2,dc=labreti,dc=it" -f gruppo2.labreti.it.aliases.ldif

