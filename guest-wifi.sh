#!/bin/sh

set -e

readonly NETWORK_NAME="guest"

network_ifname_2G=$(uci -q get misc.wireless.ifname_guest_2G)
[ -z "$network_ifname_2G" ] && exit 1
network_ifname_5G=$(uci -q get misc.wireless.ifname_guest_5G)
[ -z "$network_ifname_5G" ] && exit 1
network_device_2G=$(uci -q get misc.wireless.if_2G)
[ -z "$network_device_2G" ] && exit 1
network_device_5G=$(uci -q get misc.wireless.if_5G)
[ -z "$network_device_5G" ] && exit 1

usage() {
	echo "$0:"
	echo "    open: Reset and configure guest WiFi access point"
	echo "         $0 open <ssid> <encryption_type> <password> <uplink_if>"
	echo "    close: Stop guest WiFi access point and remove all configs"
}

guest_start() {
	local ssid="$1"
	local encryption="$2"
	local key="$3"
    local uplink_if="$4"

    uci -q batch <<-EOF >/dev/null
        set wireless.${NETWORK_NAME}_2G=wifi-iface
        set wireless.${NETWORK_NAME}_2G.device=$network_device_2G
        set wireless.${NETWORK_NAME}_2G.ifname=$network_ifname_2G
        set wireless.${NETWORK_NAME}_2G.network=$NETWORK_NAME
        set wireless.${NETWORK_NAME}_2G.mode=ap
        set wireless.${NETWORK_NAME}_2G.wpsdevicename=XiaoMiRouter
        set wireless.${NETWORK_NAME}_2G.he_ul_ofdma=0
        set wireless.${NETWORK_NAME}_2G.mscs=1
        set wireless.${NETWORK_NAME}_2G.hlos_tidoverride=1
        set wireless.${NETWORK_NAME}_2G.amsdu=2
        set wireless.${NETWORK_NAME}_2G.wnm=1
        set wireless.${NETWORK_NAME}_2G.rrm=1
        set wireless.${NETWORK_NAME}_2G.disabled=0
        set wireless.${NETWORK_NAME}_2G.ssid=$ssid
        set wireless.${NETWORK_NAME}_2G.encryption=$encryption
        set wireless.${NETWORK_NAME}_2G.key=$key
        set wireless.${NETWORK_NAME}_2G.ap_isolate=1
        set wireless.${NETWORK_NAME}_2G.ieee80211w=1
        set wireless.${NETWORK_NAME}_5G=wifi-iface
        set wireless.${NETWORK_NAME}_5G.device=$network_device_5G
        set wireless.${NETWORK_NAME}_5G.ifname=$network_ifname_5G
        set wireless.${NETWORK_NAME}_5G.network=$NETWORK_NAME
        set wireless.${NETWORK_NAME}_5G.mode=ap
        set wireless.${NETWORK_NAME}_5G.wpsdevicename=XiaoMiRouter
        set wireless.${NETWORK_NAME}_5G.he_ul_ofdma=0
        set wireless.${NETWORK_NAME}_5G.mscs=1
        set wireless.${NETWORK_NAME}_5G.hlos_tidoverride=1
        set wireless.${NETWORK_NAME}_5G.channel_block_list=52,56,60,64,100,104,108,112,116,120,124,128,132,136,140
        set wireless.${NETWORK_NAME}_5G.wnm=1
        set wireless.${NETWORK_NAME}_5G.rrm=1
        set wireless.${NETWORK_NAME}_5G.disabled=0
        set wireless.${NETWORK_NAME}_5G.ssid=$ssid
        set wireless.${NETWORK_NAME}_5G.encryption=$encryption
        set wireless.${NETWORK_NAME}_5G.key=$key
        set wireless.${NETWORK_NAME}_5G.ap_isolate=1
        set wireless.${NETWORK_NAME}_5G.ieee80211w=1
        commit wireless
        set network.${NETWORK_NAME}=interface
        set network.${NETWORK_NAME}.type=bridge
        set network.${NETWORK_NAME}.ifname="$uplink_if"
        set network.${NETWORK_NAME}.proto=none
        commit network
	EOF
    # Firewall? If firewall is up we should be fine by default? Everything is
    # dropped in INPUT, and because we are bridging multiple physdev forward
    # should be allowed.

    # Reload
	ubus call network reload
	/sbin/wifi update
	/etc/init.d/dnsmasq restart
    return 0
}

guest_stop() {
	uci -q batch <<-EOF >/dev/null
		delete firewall.guest
		delete wireless.${NETWORK_NAME}_2G
		delete wireless.${NETWORK_NAME}_5G
		delete network.${NETWORK_NAME}
        delete dhcp.${NETWORK_NAME}

		commit firewall
		commit wireless
		commit network
		commit dhcp
	EOF

	ubus call network reload
	/sbin/wifi update
	/etc/init.d/dnsmasq restart
	return 0
}

OPT=$1
case $OPT in
	open)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
            usage
            return 1
        fi
		guest_start "$2" "$3" "$4" "$5"
		return $?
	;;
	close)
		guest_stop
		return $?
	;;
	* )
		usage
		return 0
	;;
esac
