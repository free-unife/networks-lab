#!/bin/bash

#
# start_all.sh
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

systemctl stop slapd.service
systemctl stop named.service
systemctl stop nslcd.service
#freshclam
systemctl stop clamd.service
systemctl stop postfix.service
systemctl stop dovecot.service
systemctl stop amavisd.service
cd " ../../02-BIND/source"
./chg_nw_settings.sh
./chg_resolv_settings.sh
systemctl start slapd.service
systemctl start named.service
systemctl start nslcd.service
systemctl start clamd.service
systemctl start postfix.service
systemctl start dovecot.service
trust extract-compat
systemctl start amavisd.service
postfix flush
cd --

sleep 2
systemctl restart postfix.service

exit 0
