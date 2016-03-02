#!/bin/bash

#
# gen_ldif_hosts.sh
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


# Check if root is running this script.
if [ "$UID" -ne 0 ] || [ "$1" == "-h" ]; then
	echo -en "[ERROR] You must be root to run this script.\n"
	echo -en "sudo -u root $0\n"
	exit 1
fi

# Load configuration from domain.conf file
if [ -f "domain.conf" ]; then
	source "domain.conf"
else
	echo -en "[ERROR] No domain.conf file found.\n"
	exit 1
fi

# Temporary variable used for handling strings.
tmp=""

# Function that adds the generated ldif file to the LDAP server.
function addZoneToLDAP ()
{

	echo -en "Adding "$currentZone".zone.ldif to LDAP database... "
	ldapadd -H ldap://127.0.0.1 -x -W -D "cn="$admin","$domainDn"" \
-f "$currentZone".zone.ldif
	#if [ "$?" -ne 0 ]; then
	#	echo -en "[FAILED]\n"
	#	exit 1
	#fi
	echo -en "[DONE]\n"

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
# Direct zone.
# Get domain Distinguished Name.
IFS='.' read -ra tmp <<< "$domain"
domainDn="dc="${tmp[0]}",dc="${tmp[1]}",dc="${tmp[2]}""

# Get current zone values.
currentZone="$domain"
currentZoneDn="$domainDn"

serial="01"

echo -en "Generating zone $currentZone on file "$currentZone".zone.ldif... "
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
# Get current zone name.
IFS='.' read -ra tmp <<< "$IPv4Subnet"
currentZone=""${tmp[2]}"."${tmp[1]}"."${tmp[0]}"."in-addr.arpa""
currentZoneDn="$domainDn"

echo -en "Generating zone $currentZone on file "$currentZone".zone.ldif... "
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
	IFS='.' read -ra tmp <<< "${IPv4HostAddr[$i]}"
	IPv4HostAddrComp="${tmp[3]}"
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

# IPv6 reverse zone.
# Get current zone name.
tmp="${DNSIPv6Addr:0:(-5)}"
tmp=$(echo "$tmp" | rev)
IFS=':' read -ra tmp <<< "$tmp"
tmp=""${tmp[0]}""${tmp[1]}""${tmp[2]}""${tmp[3]}""${tmp[4]}""${tmp[5]}""${tmp[6]}""
tmp=$(echo "$tmp" | sed 's/.\{1\}/&./g')
currentZone=""$tmp"ip6.arpa"
currentZoneDn="$domainDn"

echo -en "Generating zone $currentZone on file "$currentZone".zone.ldif... "
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

exit 0
