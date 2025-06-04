## How to setup Guest WiFi

Run `guest-wifi.sh open <ssid> psk2 <password> eth1.4.9` to setup a guest WiFi that:

* Both 2.4GHz and 5GHz with same SSID.
* No DHCP.
* Has AP isolation.
* Bridges to `eth1.4.9` (which is a VLAN 9 on switch 1 tag 4 which is Port 4 on Xiaomi BE6500).

Just change uplink interface accordingly.
