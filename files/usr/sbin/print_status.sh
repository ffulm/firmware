#!/bin/sh

# This scripts collects information about the network status (do we have v4/v6
# internet access via wan, via freifunk, ...) to help detect and debug problems
# in our network.

set -o pipefail

print() {
	echo -n "{"
	# check internet access through WAN interface by pinging OpenDNS servers
	! ping -c1 -I br-wan 208.67.222.222 > /dev/null 2>&1
	echo -n "\"internet4wan\" : $?, "
	! ping6 -c1 -I br-wan 2620:0:ccd::2 > /dev/null 2>&1
	echo -n "\"internet6wan\" : $?, "

	# check internet access through freifunk by pinging OpenDNS servers
	! ping -c1 -I br-freifunk 208.67.222.222 > /dev/null 2>&1
	echo -n "\"internet4freifunk\" : $?, "
	! ping6 -c1 -I br-freifunk 2620:0:ccd::2 > /dev/null 2>&1
	echo -n "\"internet6freifunk\" : $?, "

	# check DNS (for IPv4) on all nameservers (WAN and freifunk)
	echo -n "\"dns4\" : { "
	nd=0
	for nameserver in $(cat /tmp/resolv.conf.auto | awk '{if($1=="nameserver") print $2;}'); do
		[ $nd -eq 0 ] && nd=1 || echo -n ", "
		! $(nslookup ipv4.google.com $nameserver | tail -n +5 | awk '{ print $3 }' | grep -q '.')
		echo -n "\"$nameserver\" : $?"
	done
	echo -n " }, "

	# check DNS (for IPv6) on all nameservers (WAN and freifunk)
	echo -n "\"dns6\" : { "
	nd=0
	for nameserver in $(cat /tmp/resolv.conf.auto | awk '{if($1=="nameserver") print $2;}'); do
		[ $nd -eq 0 ] && nd=1 || echo -n ", "
		! $(nslookup ipv6.google.com $nameserver | tail -n +5 | awk '{ print $3 }' | grep -q ':')
		echo -n "\"$nameserver\" : $?"
	done
	echo -n " }, "

	# check DNS64 on all nameservers (WAN and freifunk)
	echo -n "\"dns64\" : { "
	nd=0
	for nameserver in $(cat /tmp/resolv.conf.auto | awk '{if($1=="nameserver") print $2;}'); do
		[ $nd -eq 0 ] && nd=1 || echo -n ", "
		! $(nslookup ipv4.google.com $nameserver | tail -n +5 | awk '{ print $3 }' | grep -q ':')
		echo -n "\"$nameserver\" : $?"
	done
	echo -n " }, "

	# check NAT64 on freifunk
	! ping6 -c1 -I br-freifunk ipv4.google.com > /dev/null 2>&1
	echo -n "\"nat64\" : $?"

	echo -n "}"
}

if [ "$1" = "-p" ]; then
	publish_status="$(uci get -q freifunk.@settings[0].publish_status 2> /dev/null)"
	[ "$publish_status" != "1" ] && exit 0

	content="$(print)"
	if [ -n "$content" ]; then
		echo "$content" | alfred -s 99
		echo "status published"
	else
		echo "nothing published"
	fi
else
	print
fi
