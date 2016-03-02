#!/bin/bash

#
# chg_resolv_settings.sh
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


# This script changes the resolvconf.conf file so that DNS queries are
# possible without explicitely specifing the DNS server.

# Check if root is running this script.
if [ "$UID" -ne 0 ]; then
	echo -en "[ERROR] You must be root to run this script.\n"
	echo -en "sudo -u root $0\n"
	echo -en "OR\n"
	echo -en "sudo $0\n"
	exit 1
fi

# Load configuration from domain.conf file
if [ -f "domain.conf" ]; then
	source "domain.conf"
else
	echo -en "[ERROR] No domain.conf file found.\n"
	exit 1
fi

# Write new /etc/resolvconf.conf
echo -en "Overwriting $resolvconfconfFile... "
echo -en "\
search_domains="$domain"\n\
name_servers=\""$DNSIPv4Addr" "$DNSIPv6Addr"\"\n\
resolv_conf="$resolvconfFile"\n\
" > "$resolvconfconfFile"
echo -en "[DONE]\n"

# Force resolvconf to update all its subscribers.
resolvconf -u

exit 0
