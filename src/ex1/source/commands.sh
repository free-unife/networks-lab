#!/bin/bash

#
# commands.sh
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

# Check if root is running this script.
if [ "$UID" -ne 0 ]; then
	echo -e -n "You must be root tu run this script\n"
	echo -e -n "sudo -u root $0\n"
	exit 1
fi

#echo -en "Insert your root ldap password> "
#while [ "$ldapRootPwd" == "" ]; do
#	read "ldapRootPwd"
#done
#echo -en "[DONE]\n"

./make_cert.sh
./add_example_entries.sh
#./search_examples.sh

# End script.
exit 0
