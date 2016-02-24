#!/bin/bash

#
# add_examples_entries.sh
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
# Server initialization script.
#

# Set some empty variables
ldapHost="127.0.0.1"
ret=""
ldapRootPwd="gruppo2"

# Check if root is running this script.
if [ "$UID" -ne 0 ]; then
	echo -e -n "You must be root tu run this script\n"
	echo -e -n "sudo -u root $0\n"
	exit 1
fi

echo -en "Add example entries started..."

# Add groups and domain using domain.ldif as input file.
ldapadd -H ldaps://"$ldapHost":636 -x -w "$ldapRootPwd"  -D \
	"cn=root,dc=gruppo2,dc=labreti,dc=it" -f \
	domain.ldif
ret="$?"
#echo -e -n "Press enter to continue.\n"
#read

# Add users using users.ldif as input file.
ldapadd -H ldaps://"$ldapHost":636 -D "cn=root,dc=gruppo2,dc=labreti,dc=it" \
	-w "$ldapRootPwd" -f users.ldif
ret="$(($ret+$?))"
#echo -e -n "Press enter to continue.\n"
#read

if [ "$ret" -gt 0 ]; then
	echo -en "Add examples entries [FAILED]"
	exit 1
fi

echo -en "[OK] Add example entries.\n"

# End script.
exit 0
