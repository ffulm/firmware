#!/bin/sh

# This scripts collects information about the network status (do we have v4/v6
# internet access via wan, via freifunk, ...) to help detect and debug problems
# in our network.

set -o pipefail

print() {
    # we use a special routing table to force our packets to go through specific gateways
    ip -6 route flush table 137 2>/dev/null
    ip -6 rule del lookup 137 2>/dev/null

    echo -n "{"

    echo -n "\"date\" : \"$(date)\", "

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

    # check internet access (IPv6) through all freifunk gateways
    echo -n "\"internet6\" : { "
    nd=0
    for gateway in $(ip -6 route | grep default | grep freifunk | awk '{print $5}' | sort | uniq); do
        [ $nd -eq 0 ] && nd=1 || echo -n ", "
        ip -6 route add table 137 default from :: via $gateway dev br-freifunk 2>/dev/null
        ip -6 rule add to 2620:0:ccd::2 lookup 137 2>/dev/null
        ! ping6 -c1 -I br-freifunk 2620:0:ccd::2 > /dev/null 2>&1
        echo -n "\"$gateway\" : $?"
        ip -6 rule del lookup 137 2>/dev/null
        ip -6 route flush table 137 2>/dev/null
    done
    echo -n " }, "

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
        ! $(nslookup ipv6.google.com $nameserver 2>/dev/null| tail -n +5 | awk '{ print $3 }' | grep -q ':')
        echo -n "\"$nameserver\" : $?"
    done
    echo -n " }, "

    # check DNS64 on all nameservers (WAN and freifunk)
    echo -n "\"dns64\" : { "
    nd=0
    ip64="x" #we store the IPv6 of ipv4.google.com to test nat64 later
    for nameserver in $(cat /tmp/resolv.conf.auto | awk '{if($1=="nameserver") print $2;}'); do
        [ $nd -eq 0 ] && nd=1 || echo -n ", "
        ! ip64_=$(nslookup ipv4.google.com $nameserver 2>/dev/null| tail -n +5 | awk '{ print $3 }' | grep ':' | head -1)
        echo -n "\"$nameserver\" : $?"
        ip64=${ip64_:-$ip64}
    done
    echo -n " }, "

    # check NAT64 through all freifunk gateways
    echo -n "\"nat64\" : { "
    nd=0
    [[ "$ip64" = "x" ]] ||
    for gateway in $(ip -6 route | grep default | grep freifunk | awk '{print $5}' | sort | uniq); do
        [ $nd -eq 0 ] && nd=1 || echo -n ", "
        ip -6 route add table 137 default from :: via $gateway dev br-freifunk 2>/dev/null
        ip -6 rule add to $ip64 lookup 137 2>/dev/null
        ! ping6 -c1 -I br-freifunk $ip64 > /dev/null 2>&1
        echo -n "\"$gateway\" : $?"
        ip -6 rule del lookup 137 2>/dev/null
        ip -6 route flush table 137 2>/dev/null
    done
    echo -n " }"

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
