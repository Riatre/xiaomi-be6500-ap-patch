#!/bin/sh

export PATH=/usr/sbin:/usr/bin:/sbin:/bin

if [ -f /tmp/mod_run_ok ]; then
    exit 0
fi

debloat_once() {
    # See /etc/rc.d/S90miio_client; this effectively disables the miio_client
    uci set miio_ot.ot.ver=1
    uci commit miio_ot

    uci set messaging.setting.enable=0
    uci commit messaging

    uci set otapred.settings.enabled=0
    uci set misc.ota_pred.download=0
    uci commit otapred
    uci commit misc
}

install() {
    mkdir -p /data/mod
    cp "$0" /data/mod/mod.sh
    chmod +x /data/mod/mod.sh

    if ! grep mod/mod /etc/crontabs/root; then
        cat > /etc/crontabs/root <<EOF
*/2 * * * * command -v logrotate >/dev/null && logrotate /etc/logrotate.conf
*/15 * * * * /usr/sbin/ntpsetclock 60 log >/dev/null 2>&1
0 */6 * * * command -v sec_cfg_bak.sh >/dev/null && sec_cfg_bak.sh
*/1 * * * * /usr/sbin/lanap_mode.sh check_gw
*/1 * * * * /data/mod/mod.sh > /tmp/modlog 2>&1
EOF
    fi
    echo "Installed to /data/mod/mod.sh"
    echo "Added trigger to /etc/crontabs/root"

    debloat_once
}

stub_out_service() {
    _service_file="/etc/init.d/$1"
    _tmp_file="${_service_file}.tmp"
    
    if [ ! -f "$_service_file" ]; then
        echo "Service file $_service_file not found" >&2
        return 1
    fi

    {
        cat "$_service_file"
        echo
        echo 'unset -f start_service'
        echo 'start_service() {'
        echo '  return 0'
        echo '}'
    } > "$_tmp_file" && chmod +x "$_tmp_file" && mv "$_tmp_file" "$_service_file"
}

nuke() {
    stub_out_service "$1"
    /etc/init.d/"$1" stop
    /etc/init.d/"$1" disable
}

debloat_per_boot() {
    nuke xqbc
    nuke cab_meshd
    nuke miwifi-discovery
    nuke xiaoqiang_sync
    nuke mosquitto
    nuke tbusd
    nuke messagingagent.sh
    nuke xq_info_sync_mqtt
    nuke smartcontroller
}

enable_firewall() {
    sed -i 's/lanapmode/xmsb/g' /etc/init.d/firewall
    /etc/init.d/firewall start
}

fix_ssh_per_boot() {
    # shellcheck disable=SC2016 # We want to substitute verbatim string "$string"
    sed -i 's/-o "$channel" = "release"//g' /etc/init.d/dropbear
    /etc/init.d/dropbear restart
}

if [ "$1" = "install" ]; then
    install
    exit 0
fi

debloat_per_boot
fix_ssh_per_boot
enable_firewall

touch /tmp/mod_run_ok
