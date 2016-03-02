#!/bin/bash

#
# search_examples.sh
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
# Search examples script.
#


echo -e -n "\n\n[INFO] Query examples started.\n\n"

# Test query.
echo -e -n "ldapsearch -x -b 'dc=gruppo2,dc=labreti,dc=it' '(objectClass=*)'\n"
ldapsearch -x -b 'dc=gruppo2,dc=labreti,dc=it' '(objectClass=*)'
echo -e -n "Press enter to continue.\n"
read

# Searching for a user (without password authentication).
echo -e -n "ldapsearch -x -b 'dc=gruppo2,dc=labreti,dc=it' '(cn=Franco \
	Masotti)'\n"
ldapsearch -x -b 'dc=gruppo2,dc=labreti,dc=it' '(cn=Franco Masotti)'
echo -e -n "Press enter to continue.\n"
read

# Query with authentication to show sensible data.
echo -e -n "ldapsearch -W -D "cn=root,dc=gruppo2,dc=labreti,dc=it" \
	'(uid=francomasotti)'\n"
ldapsearch -W -D "cn=root,dc=gruppo2,dc=labreti,dc=it" '(uid=francomasotti)'
echo -e -n "Press enter to continue.\n"
read

# Print db status.
echo -e -n "\n\n[INFO] Printing database status:\n\n"
slapcat

echo -e -n "\n\n[MAYBE OK] Query examples.\n\n"

# End script.
exit 0
