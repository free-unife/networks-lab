#!/bin/bash

#
# restore_all.sh
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


if [ "$UID" -ne 0 ] || [ "$1" == "-h" ]; then
        echo -en "[ERROR] You must be root to run this script.\n"
        echo -en "sudo -u root $0\n"
        echo -en "OR\n"
        echo -en "sudo $0\n"
        exit 1
fi

systemctl stop nslcd.service
cd "../../01-OpenLDAP/source"
./commands.sh
cd "../../02-BIND/source"
./setup_dns.sh -aal
cd "../../03-Mail/source"
./add_mx_and_aliases_ldap.sh
./start_all.sh

exit 0
