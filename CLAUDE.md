This is a project to mod my own MiWiFi RN02 Router.

The router is on QCA platform and runs a heavily modified QSDK (which itself is based on OpenWRT).

Goal:
* Debloat - remove all unnecessary components, for example I don't use their app management feature (which is scary, requires a MQTT connection to their server, meaning that Xiaomi servers can just push whatever they want to my router).
* Use the router as a wireless access point. The device has a built-in AP mode which mostly works, but has some warts.
* Have a guest WiFi SSID which is password protected. It should forward traffic to my main router with VLAN tag=9. This is not something the device supports out of the box.

Progress:
* Found a way to get SSH root access to the router.
* Found a way to persist my changes to the router.

To access the router, use `ssh -oHostKeyAlgorithms=+ssh-rsa root@172.30.80.173`.
The SSH option is required as it runs an old version of Dropbear which only supports ssh-rsa.

## How to persist changes

`/` is a squashfs filesystem, hence read-only. There's also no overlay.
`/etc/config` points to a ext4 file on an ubifs. Other `/etc` files are on a tmpfs created during boot and copied over from the squashfs.

The hotupgrade system allows persistent file modifications on the read-only squashfs root filesystem by using bind mounts during boot.

The code is located at `rootfs/lib/preinit/91_mount_hotupgrade` if you want to take a look at details.

**How it works:**
1. Modified files are stored in `/data/hotupgrade/{name}/mountfile/` with the same directory structure as the target filesystem
2. During boot, `91_mount_hotupgrade` checks for completed hotupgrade packages (status file contains `0`)
3. `hotupgrade_file_mount()` bind-mounts each file from the hotupgrade directory to its corresponding system location as read-only
4. This effectively overlays custom files over the original squashfs files without modifying the underlying filesystem

**Key components:**
- `/data/hotupgrade/` - persistent storage for hotupgrade packages
- `hotupgrade_status` - status file (must contain `0` for successful completion)
- `mountfile/` subdirectory - contains the actual replacement files in filesystem hierarchy
- Files are mounted read-only to prevent runtime modification

**Use case:** This is the primary method to persist changes to `/usr`, `/bin`, `/etc` and other normally read-only directories on the MiWiFi router.

## Using make-patch.py

The `make-patch.py` script automates the creation of hotupgrade packages for applying file patches.

**Usage:**
1. Edit the `PATCHED_FILES` dictionary in `make-patch.py` to map target paths to source files:
   ```python
   PATCHED_FILES = {
       '/etc/rc.local': 'patch/rc.local',
       '/usr/bin/custom_script': 'patch/custom_script',
   }
   ```

2. Create your patch files in the project directory (e.g., `patch/rc.local`)

3. Run the script:
   ```bash
   ./make-patch.py
   ```

4. Apply the generated tar package to the router:
   ```bash
   cat patch.tar | ssh -oHostKeyAlgorithms=+ssh-rsa root@172.30.80.173 'tar x -C /data/hotupgrade -f -'
   ```

5. Reboot the router to apply changes
