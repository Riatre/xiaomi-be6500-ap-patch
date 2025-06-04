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
}


def create_hotupgrade_package():
    """Create hotupgrade tar package"""
    package_name = "patch"
    tar_filename = f"{package_name}.tar"

    # Create tar in memory
    with tarfile.open(tar_filename, "w") as tar:
        # Add status file
        status_info = tarfile.TarInfo(name=f"{package_name}/hotupgrade_status")
        status_info.size = 1
        status_info.mode = 0o644
        status_info.uid = 0
        status_info.gid = 0
        status_info.uname = "root"
        status_info.gname = "root"
        tar.addfile(status_info, BytesIO(b"0"))

        # Add each patch file
        for target_path, source_file in PATCHED_FILES.items():
            source_path = Path(source_file)
            if not source_path.exists():
                raise FileNotFoundError(f"Source file {source_file} does not exist")

            # Read source file
            file_content = source_path.read_bytes()
            file_mode = source_path.stat().st_mode & 0o777

            # Create tar info for the file
            tar_path = f"{package_name}/mountfile{target_path}"
            file_info = tarfile.TarInfo(name=tar_path)
            file_info.size = len(file_content)
            file_info.mode = file_mode
            file_info.uid = 0
            file_info.gid = 0
            file_info.uname = "root"
            file_info.gname = "root"

            # Add file to tar
            tar.addfile(file_info, BytesIO(file_content))
            print(f"Added {target_path} -> {source_file} (mode: {oct(file_mode)})")

    print(f"\nHotupgrade package created: {tar_filename}")
    print(
        f"To apply on router: cat {tar_filename} | ssh -oHostKeyAlgorithms=+ssh-rsa root@miwifi.com 'tar x -C /data/hotupgrade -f -'"
    )
    print("Then reboot the router to apply changes.")


if __name__ == "__main__":
    create_hotupgrade_package()
