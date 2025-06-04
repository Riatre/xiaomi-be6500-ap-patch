#!/usr/bin/env python3
"""
0% human made. Use at your own risk.

MiWiFi Hotupgrade Patch Generator

This script creates a tar package that can be extracted to /data/hotupgrade
to persist file patches over reboots using the router's hotupgrade system.
"""

import tarfile
from pathlib import Path
from io import BytesIO

# Configuration: Map target paths to source files in the project
PATCHED_FILES = {
    "/etc/rc.local": "patch/rc.local",
    "/etc/init.d/dropbear": "patch/dropbear",
    "/etc/init.d/telnet": "patch/telnet",
    # Used to call boot hook script.
    "/etc/init.d/sysfixtime": "patch/sysfixtime",
}
EXTRA_FILES = {
    "early-boot-hook": "patch/early-boot-hook",
}


def _addfile(tar: tarfile.TarFile, target_path: str, content: bytes, mode: int):
    file_info = tarfile.TarInfo(name=target_path)
    file_info.size = len(content)
    file_info.mode = mode
    file_info.uid = 0
    file_info.gid = 0
    file_info.uname = "root"
    file_info.gname = "root"
    tar.addfile(file_info, BytesIO(content))


def create_hotupgrade_package():
    """Create hotupgrade tar package"""
    package_name = "patch"
    tar_filename = f"{package_name}.tar"

    # Create tar in memory
    with tarfile.open(tar_filename, "w") as tar:
        # Add status file
        _addfile(tar, f"{package_name}/hotupgrade_status", b"0", 0o644)

        files = {
            f"{package_name}/mountfile{dest}": src
            for dest, src in PATCHED_FILES.items()
        }
        files |= {
            f"{package_name}/extra/{dest}": src for dest, src in EXTRA_FILES.items()
        }
        # Add each patch file
        for target_path, source_file in files.items():
            source_path = Path(source_file)
            mode = source_path.stat().st_mode & 0o777
            _addfile(tar, target_path, source_path.read_bytes(), mode)
            print(f"Added {target_path} -> {source_file} (mode: {oct(mode)})")

    print(f"\nHotupgrade package created: {tar_filename}")
    print(
        f"To apply on router: cat {tar_filename} | ssh -oHostKeyAlgorithms=+ssh-rsa root@miwifi.com 'tar x -C /data/hotupgrade -f -'"
    )
    print("Then reboot the router to apply changes.")


if __name__ == "__main__":
    create_hotupgrade_package()
