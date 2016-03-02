#!/bin/bash

#
# chg_nw_settings.sh
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


# This script changes the network configuration for the current session.
# At the next reboot these settings will be forgotten.

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

# If Network Manager exists and it's running.
ps aux | grep NetworkManager | grep -v grep > /dev/null
if [ "$?" -eq 0 ]; then
	killall NetworkManager
	sleep 1
fi
# Get dynamic addresses fo all intrerfaces.
# If dhcpcd is not running start it.
ps aux | grep dhcpcd | grep -v grep > /dev/null
if [ "$?" -ne 0 ]; then
	dhcpcd > /dev/null
else
	killall dhcpcd
	dhcpcd > /dev/null
fi

# Get a static ip address for one interface.
# Set prefix of network interface (e.g. enp).
nwCardNamePrefix="enp"
# Get wired ethernet name.
interface=$(ip addr | grep "$nwCardNamePrefix" -m 1 | awk ' {print $2} ')
interface=${interface:0:(-1)}
# Set v4 and v6 addresses, valid untill reboot.
# Remove previous nw config on device.
ip addr flush dev "$interface"
# Change network interface's ip with ip command.
# Set dev up.
ip link set up dev "$interface"
# v4
ip addr add "$DNSIPv4Addr"/"$IPv4NetMask" brd + dev "$interface"
# Wait to avoid problems setting IPv6 address.
sleep 1
# v6
ip addr add scope global "$DNSIPv6Addr"/"$IPv6NetMask" dev "$interface"
ip link set multicast on dev "$interface"

exit 0
