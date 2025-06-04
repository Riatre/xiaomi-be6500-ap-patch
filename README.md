## What?

Mod my MiWiFi RN02 (Xiaomi BE6500, **not** the Pro one) Router to disable bullshit features and use it as a wireless access point with guest WiFi VLAN support.

## Start

Use one of the exploits documented in https://github.com/openwrt-xiaomi/xmir-patcher. Reset the router after and use `./enable-ssh` to bring back SSH.

Then, go to the web interface, enable AP mode, tweak settings as you like.

## Install Patch

Run `make-patch.py` to create a patch.tar file:

```bash
./make-patch.py
cat patch.tar | ssh -oHostKeyAlgorithms=+ssh-rsa root@miwifi.com 'tar x -C /data/hotupgrade -f -'
```

Reboot router to apply changes.

What it does:

1. Disable anything that listens on 0.0.0.0, except dropbear for SSH. That includes luci and dnsmasq. **Do not use this patch as-is if you want to use your router as a, well, router.**
2. Patch the stupid release channel check, make sure dropbear starts.
3. Provides guest WiFi setup script.

You may still enable LUCI with `service nginx start` and change AP settings in the web interface.

## Guest WiFi Setup

Run `/data/hotupgrade/patch/extra/guest-wifi.sh open <ssid> psk2 <password> <uplink_if>` to setup a guest WiFi that:

* Both 2.4GHz and 5GHz with same SSID
* No DHCP
* Has AP isolation  
* Bridges to uplink interface (e.g., `eth1.4.9` for VLAN 9 on router port 4)

Example:
```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@miwifi.com
/data/hotupgrade/patch/extra/guest-wifi.sh open "Guest" psk2 "password123" eth1.4.9
```

To disable: `/data/hotupgrade/patch/extra/guest-wifi.sh close`

## How Persistence Works

Uses router's hotupgrade system:
- Modified files stored in `/data/hotupgrade/{name}/mountfile/` 
- Boot script bind-mounts files over original system files
- Files mounted read-only

### Customization

Add stuff you want to run on boot to `patch/early-boot-hook`. Add commands you want to run after init finishes to `patch/rc.local`.

## Files

- `make-patch.py` - generates hotupgrade package
- `patch/` - replacement system files
- `enable-ssh` - convenience script to enable SSH after router reset (requires telnet access first)
