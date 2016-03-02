#!/bin/bash

#
# setup_dns.sh
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


# This script reads the configuration from domain.conf file and creates a DNS
# server in a few seconds.
# You can choose between bind zone files or the ldap backend.
#

function disableResolvconfconf ()
{
	rcc="$1"
	rc="$2"
	echo -en "Disabling "$rcc" entries... "

	echo -en "\
resolv_conf="$rc"\n\
" > "$rcc"

	# Force resolvconf to update all its subscribers.
	resolvconf -u

	echo -en "[DONE]\n"

	return

}

function checkZones ()
{

	zoneName="$1"
	zoneFile="$2"

	echo -en "Checking zone file of $zoneName... \n"

	named-checkzone "$zoneName" "$zoneFile"
	if [ "$?" -ne 0 ]; then
		echo -en "[ERROR] Invalid zone file configuration \
("$zoneFile"). Aborting.\n"
		exit 1
	fi

	return
}

# Function that adds the generated ldif file to the LDAP server.
function addZoneToLDAP ()
{

	echo -en "Adding "$currentZone".zone.ldif to LDAP database... "
	ldapadd -H ldap://"$ldapServerIPv4Addr" -x -w "$ldapRootPwd" -D \
"cn="$admin","$domainDn"" -f "$currentZone".zone.ldif
	#if [ "$?" -ne 0 ]; then
	#	echo -en "[FAILED]\n"
	#	exit 1
	#fi
	echo -en "[DONE]\n"

	return

}

# Function that extracts the IPv4 host zone component of an address.
function getIPv4AddrComp ()
{

	IPv4Addr="$1"
	tmp=""

	IFS='.' read -ra tmp <<< "$IPv4Addr"
	IPv4HostAddrComp="${tmp[3]}"
	echo "$IPv4HostAddrComp"

	return

}

# Function that extracts the IPv4 zone name.
function getIPv4ZoneName ()
{

	IPv4Addr="$1"
	type="$2"
	tmp=""


	# Get current zone name.
	IFS='.' read -ra tmp <<< "$IPv4Addr"
	currentZone=""${tmp[2]}"."${tmp[1]}"."${tmp[0]}".in-addr.arpa"
	echo "$currentZone"

	return

}

# Function that extracts the IPv6 host zone component of an address.
function getIPv6AddrComp ()
{

	IPv6Addr="$1"
	tmp=""


	tmp=$(echo "$IPv6Addr" | rev)
	IFS=':' read -ra tmp <<< "$tmp"
	tmp=$(echo "$tmp" | sed 's/.\{1\}/&./g')
	IPv6HostAddrComp="${tmp:0:(-1)}"
	echo "$IPv6HostAddrComp"

	return

}

# Function that extracts the IPv6 zone name.
function getIPv6ZoneName ()
{

	IPv6Addr="$1"
	type="$2"
	tmp=""

	# Get current zone name.
	tmp="${IPv6Addr:0:(-5)}"
	tmp=$(echo "$tmp" | rev)
	IFS=':' read -ra tmp <<< "$tmp"
	tmp=""${tmp[0]}""${tmp[1]}""${tmp[2]}"\
"${tmp[3]}""${tmp[4]}""${tmp[5]}""${tmp[6]}""
	tmp=$(echo "$tmp" | sed 's/.\{1\}/&./g')
	if [ "$type" == "file" ]; then
		# Zone files have the '.' after arpa.
		currentZone=""$tmp"ip6.arpa."
	else
		# ldap db.
		currentZone=""$tmp"ip6.arpa"
	fi
	echo "$currentZone"


	return

}

# Function that writes common information in /etc/named.conf in both cases.
function writeGloblToNamedConf ()
{

	echo -en "\
options {\n\
\tdirectory \""$zoneFilesDir"\";\n\
\tlisten-on port "$DNSPort" { any; };\n\
\tlisten-on-v6 port "$DNSPort" { any; };\n\
\tlisten-on port "$DNSPort" { "$DNSIPv4Addr"; "$DNSIPv6Addr"; };\n\
\tallow-recursion { "$IPv4Subnet"/"$IPv4NetMask"; "$DNSIPv4Addr"; \
"$IPv6Subnet"/"$IPv6NetMask"; "$DNSIPv6Addr";};\n\
};\n
zone \".\" {\n\
\ttype hint;\n\
\tfile \"root.hint\";\n\
};\n\n\
" > "$namedConfFile"

	return

}

# Function which writes ldap type zone entries.
function writeZoneInfoToNamedConfLDAP ()
{

	currentZone="$1"
	currentZoneDn="$2"


	echo -en "\
zone \""$currentZone"\" IN {
\ttype master;
\tdatabase \"ldap \
ldap://"$ldapServerIPv4Addr"/zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn" "$defaultTTL"\";
\tallow-query { any; };
};\n\n\
" >> "$namedConfFile"

	return

}

# Function which writes classical zone entries.
function writeZoneInfoToNamedConfFILE ()
{

	currentZone="$1"


	echo -en "\
zone \""$currentZone"\" IN {\n\
\ttype master;\n\
\tfile \""$currentZone"\";\n\
\tallow-query { any; };\n\
};\n\n\
" >> "$namedConfFile"

	return

}

# Core functions.
# All, zones.
function az ()
{
	# Try to create dir.
	mkdir -p "$zoneFilesDir"

	echo -en "Writing configuration to files... "
	echo "$currentZone"

	# Write common config to named.conf file.
	writeGloblToNamedConf

	# Write direct zone info to named.conf file.
	writeZoneInfoToNamedConfFILE "$currentZone"

	# Change file permissions.
	chown root:named "$namedConfFile"

	# If zonefile is changed on the fly serial must be incremented each
	# time.
	# But since we restart named, we don't care about this problem.
	serial="01"
	i=0
	echo -en "\
\$TTL "$TTL"\n\
@\tIN\tSOA\tns."$domain".\t"$admin"."$domain". (\n\
$(date "+%Y%m%d")"$serial"\t; serial\n\
"$refresh"\t; refresh\n\
"$retry"\t; retry\n\
"$expiry"\t; expiry\n\
"$minimum" )\t; minimum\n\
@\tIN\tNS\tns."$domain".\n\
ns."$domain".\tIN\tAAAA\t"$DNSIPv6Addr"\n\
ns."$domain".\tIN\tA\t"$DNSIPv4Addr"\n\
$(for host in $hostNames; do
	echo -en ""$host"."$domain".\tIN\tA\t"
	echo -en "${IPv4HostAddr[$i]}\n"
	echo -en ""$host"."$domain".\tIN\tAAAA\t"
	echo -en "${IPv6HostAddr[$i]}\n"
	i=$(($i+1))
done)
" > "$zoneFilesDir/$currentZone"

	checkZones "$currentZone" "$zoneFilesDir/$currentZone"

	# Reverse zones.

	# Reverse zone IPv4.

	currentZone=$(getIPv4ZoneName "$IPv4Subnet")
	writeZoneInfoToNamedConfFILE "$currentZone"

	i=0
	echo -en "\
\$ORIGIN "$currentZone".\n\
\$TTL "$TTL"\n\
@\tIN\tSOA\tns."$domain".\t"$admin"."$domain". (\n\
$(date "+%Y%m%d")"$serial"\t; serial\n\
"$refresh"\t; refresh\n\
"$retry"\t; retry\n\
"$expiry"\t; expiry\n\
"$minimum" )\t; minimum\n\
"$currentZone".\tIN\tNS\tns."$domain."\n\
$(DNSIPv4AddrComp=$(getIPv4AddrComp "$DNSIPv4Addr")
echo -en ""$DNSIPv4AddrComp"\tIN\tPTR\tns."$domain".\n")
$(for host in $hostNames; do
	IPv4HostAddrComp=$(getIPv4AddrComp "${IPv4HostAddr[$i]}")
	echo -en ""$IPv4HostAddrComp"\tIN\tPTR\t"$host"."$domain".\n"
	i=$(($i+1))
done)
" > "$zoneFilesDir/$currentZone"

	checkZones "$currentZone" "$zoneFilesDir/$currentZone"

	# Reverse zone IPv6

	currentZone=$(getIPv6ZoneName "$IPv6Subnet" "file")
	writeZoneInfoToNamedConfFILE "$currentZone"

# N.B. Absence of '.' at the end of "$currentZone" because already included.
	i=0
	echo -en "\
\$ORIGIN "$currentZone"\n\
\$TTL "$TTL"\n\
@\tIN\tSOA\tns."$domain".\t"$admin"."$domain". (\n\
$(date "+%Y%m%d")"$serial"\t; serial\n\
"$refresh"\t; refresh\n\
"$retry"\t; retry\n\
"$expiry"\t; expiry\n\
"$minimum" )\t; minimum\n\
"$currentZone"\tIN\tNS\tns."$domain".\n\
$(DNSIPv6AddrComp=$(getIPv6AddrComp "$DNSIPv6Addr")
echo -en ""$DNSIPv6AddrComp"\tIN\tPTR\tns."$domain".\n")
$(for host in $hostNames; do
	IPv6HostAddrComp=$(getIPv6AddrComp "${IPv6HostAddr[$i]}")
	echo -en ""$IPv6HostAddrComp"\tIN\tPTR\t"$host"."$domain".\n"
	i=$(($i+1))
done)
" > "$zoneFilesDir/$currentZone"

	checkZones "$currentZone" "$zoneFilesDir/$currentZone"

	echo -en "[DONE]\n"

	return

}

# All, LDAP backend.
function al ()
{

	# Direct zone.

	serial="01"

	# Write initial configuration to named.conf.
	writeGloblToNamedConf

	# Write zone info
	writeZoneInfoToNamedConfLDAP "$currentZone" "$currentZoneDn"

	echo -en "Generating zone "$currentZone" on file \
"$currentZone".zone.ldif... "
	i=0
	echo -en "\
# Zone definition.\n\
dn: zoneName="$currentZone",ou="$hostsOu","$currentZoneDn"\n\
objectClass: dNSZone\n\
zoneName: "$currentZone"\n\
relativeDomainName: "$currentZone"\n\n\
# SOA.\n\
dn: relativeDomainName=@,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: @\n\
zoneName: "$currentZone"\n\
dNSTTL: "$defaultTTL"\n\
dNSClass: NS\n\
sOARecord: ns."$domain". "$admin"."$domain". $(date "+%Y%m%d")"$serial"\
 "$TTL" "$refresh" "$retry" "$expiry"\n\
nSRecord: ns."$domain".\n\n\
# Name server.\n\
dn: relativeDomainName=ns,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: ns\n\
zoneName: "$currentZone"\n\
dNSTTL: "$defaultTTL"\n\
dNSClass: IN\n\
aRecord: "$DNSIPv4Addr"\n\
aAAARecord: "$DNSIPv6Addr"\n\n\
$(for host in $hostNames; do
	echo -en "\
# Host "$host".\n\
dn: relativeDomainName="$host",zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: "$host"\n\
zoneName: "$currentZone"\n\
$(if [ "${#hostTTL[@]}" -le "$i" ]; then
	echo -en "dNSTTL: "$defaultTTL"\n"
else
	echo -en "dNSTTL: "${hostTTL[$i]}"\n"
fi)
dNSClass: IN\n\
aRecord: "${IPv4HostAddr[$i]}"\n\
aAAARecord: "${IPv6HostAddr[$i]}"\n\n"
	i=$(($i+1))
done)
" > "$currentZone".zone.ldif

	echo -en "[DONE] \n"

	addZoneToLDAP

	# IPv4 reverse zone.
	currentZone=$(getIPv4ZoneName "$IPv4Subnet")
	currentZoneDn="$domainDn"

	# Write zone info
	writeZoneInfoToNamedConfLDAP "$currentZone" "$currentZoneDn"

	echo -en "Generating zone "$currentZone" on file \
	"$currentZone".zone.ldif... "
	i=0
	echo -en "\
# Zone definition.\n\
dn: zoneName="$currentZone",ou="$hostsOu","$currentZoneDn"\n\
objectClass: dNSZone\n\
zoneName: "$currentZone"\n\
relativeDomainName: "$currentZone"\n\n\
# SOA.\n\
dn: relativeDomainName=@,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: @\n\
zoneName: "$currentZone"\n\
dNSTTL: "$defaultTTL"\n\
dNSClass: NS\n\
sOARecord: ns."$domain". "$admin"."$domain". $(date "+%Y%m%d")"$serial"\
 "$TTL" "$refresh" "$retry" "$expiry"\n\
nSRecord: ns."$domain".\n\n\
# Name server.\n\
dn: relativeDomainName=ns,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
$(IFS='.' read -ra tmp <<< "$DNSIPv4Addr"
DNSIPv4AddrComp="${tmp[3]}"
echo -en "relativeDomainName: "$DNSIPv4AddrComp"\n")
zoneName: "$currentZone"\n\
pTRRecord:ns."$domain".\n\n\
$(for host in $hostNames; do
	IPv4HostAddrComp=$(getIPv4AddrComp "${IPv4HostAddr[$i]}")
	echo -en "\
# Host "$host".\n\
dn: relativeDomainName="$host",zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: "$IPv4HostAddrComp"\n\
zoneName: "$currentZone"\n\
pTRRecord:"$host"."$domain".\n\n"
	i=$(($i+1))
done)
" >  "$currentZone".zone.ldif

	echo -en "[DONE] \n"

	addZoneToLDAP

	# Get current Zone Name.
	currentZone=$(getIPv6ZoneName "$DNSIPv6Addr" "ldap")
	currentZoneDn="$domainDn"

	# Write zone info
	writeZoneInfoToNamedConfLDAP "$currentZone" "$currentZoneDn"

	echo -en "Generating zone "$currentZone" on file \
	"$currentZone".zone.ldif... "
	i=0
	echo -en "\
# Zone definition.\n\
dn: zoneName="$currentZone",ou="$hostsOu","$currentZoneDn"\n\
objectClass: dNSZone\n\
zoneName: "$currentZone"\n\
relativeDomainName: "$currentZone"\n\n\
# SOA.\n\
dn: relativeDomainName=@,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: @\n\
zoneName: "$currentZone"\n\
dNSTTL: "$defaultTTL"\n\
dNSClass: NS\n\
sOARecord: ns."$domain". "$admin"."$domain". $(date "+%Y%m%d")"$serial"\
 "$TTL" "$refresh" "$retry" "$expiry"\n\
nSRecord: ns."$domain".\n\n\
# Name server.\n\
dn: relativeDomainName=ns,zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
$(DNSIPv6AddrComp=$(getIPv6AddrComp "$DNSIPv6Addr")
echo -en "relativeDomainName: "$DNSIPv6AddrComp"\n")
zoneName: "$currentZone"\n\
pTRRecord:ns."$domain".\n\n\
$(for host in $hostNames; do
	IPv6HostAddrComp=$(getIPv6AddrComp "${IPv6HostAddr[$i]}")
	echo -en "\
# Host "$host".\n\
dn: relativeDomainName="$host",zoneName="$currentZone",ou="$hostsOu",\
"$currentZoneDn"\n\
objectClass: dNSZone\n\
relativeDomainName: "$IPv6HostAddrComp"\n\
zoneName: "$currentZone"\n\
pTRRecord:"$host"."$domain".\n\n"
	i=$(($i+1))
done)
" >  "$currentZone".zone.ldif

	echo -en "[DONE] \n"

	addZoneToLDAP

	return

}

# Check if root is running this script.
if [ "$UID" -ne 0 ] || [ "$1" == "-h" ]; then
	echo -en "[ERROR] You must be root to run this script.\n"
	echo -en "sudo -u root $0\n"
	echo -en "OR\n"
	echo -en "sudo $0\n"
	echo -en "Help:\n"
	echo -en "\t$0 -d ;deletes resolv settings.\n"
	echo -en "\t$0 -az ;makes all the necessary configuration with the \
zone files.\n"
	echo -en "\t$0 -al ;makes all the necessary configuration with LDAP \
as database.\n"
	echo -en "\t$0 -aaz ;makes all the necessary configuration with the \
zone files and modifies network parameters.\n"
	echo -en "\t$0 -aal ;makes all the necessary configuration with LDAP \
as database and modifies network parameters.\n"
	exit 1
fi

# Load configuration from domain.conf file
if [ -f "domain.conf" ]; then
	source "domain.conf"
else
	echo -en "[ERROR] No domain.conf file found.\n"
	exit 1
fi


# Global variables
tmp=""

# Get domain Distinguished Name.
IFS='.' read -ra tmp <<< "$domain"
domainDn="dc="${tmp[0]}",dc="${tmp[1]}",dc="${tmp[2]}""

# Get current zone values.
currentZone="$domain"
currentZoneDn="$domainDn"

# End of global variables.

if [ "$1" == "-d" ]; then
	disableResolvconfconf "$resolvconfconfFile" "$resolvconfFile"
	exit 0
fi

# stop BIND daemon.
systemctl stop named.service

systemctl disable named.service

# Make all.
if [ "$1" == "-aaz" ] || [ "$1" == "-aal" ]; then
	# Call the network changing script.
	./chg_nw_settings.sh
	# Call the resolv.conf script
	./chg_resolv_settings.sh
fi

# Call az.
if [ "$1" == "-az" ] || [ "$1" == "-aaz" ]; then
	az
fi
# Call al.
if [ "$1" == "-al" ] || [ "$1" == "-aal" ]; then
	al
fi

# Enable named.service.
systemctl enable named.service

# Start BIND daemon.
systemctl start named.service

exit 0

# Another way instead of using read.
#reverse=$(echo "$DNSIPv4Addr" | rev)
#indexPoint=$(expr index "$reverse" .)
#indexPoint=$(($indexPoint-1))
#reverseString=${reverse:0:$indexPoint}
#domainString=$(echo "$reverseString" | rev)
