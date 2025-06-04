#!/bin/sh

set -e

# Remove bloats from cron.
cat > /etc/crontabs/root <<EOF
*/2 * * * * command -v logrotate >/dev/null && logrotate /etc/logrotate.conf
*/15 * * * * /usr/sbin/ntpsetclock 60 log >/dev/null 2>&1
0 */6 * * * command -v sec_cfg_bak.sh >/dev/null && sec_cfg_bak.sh
*/1 * * * * /usr/sbin/lanap_mode.sh check_gw
EOF

# See /etc/rc.d/S90miio_client; this effectively disables the miio_client
uci set miio_ot.ot.ver=1
uci commit miio_ot

uci set messaging.setting.enable=0
uci commit messaging

uci set otapred.settings.enabled=0
uci set misc.ota_pred.download=0
uci commit otapred
uci commit misc

# Disable hidden backhaul AP (I don't use Mesh)
uci set wireless.bh_ap_2g.disabled=1
uci set wireless.bh_ap_5g.disabled=1
# Disable hidden MIoT netcfg AP
# wireless.miot_2G.encryption='none', no firewall, seriously?
# (well, there are firewall rules for MIoT, but guess what, it's disabled for lanapmode)
uci set wireless.miot_2G.disabled=1
uci commit wireless
