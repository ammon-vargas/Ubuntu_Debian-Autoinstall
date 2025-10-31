# Automated Installation for Ubuntu and Debian

This repository contains the necessary configuration files to create custom bootable ISOs for automated installations of Ubuntu Server and Debian. It provides various options for both fully automated (zero-touch) and semi-automated (interactive) setups.

## Table of Contents

- [Automated Installation for Ubuntu and Debian](#automated-installation-for-ubuntu-and-debian)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Ubuntu Autoinstall](#ubuntu-autoinstall)
    - [Notable Options (Ubuntu)](#notable-options-ubuntu)
    - [How It Works (Ubuntu)](#how-it-works-ubuntu)
  - [Debian Autoinstall (Preseed)](#debian-autoinstall-preseed)
    - [Notable Options (Debian)](#notable-options-debian)
    - [How It Works (Debian)](#how-it-works-debian)
  - [Cautions and Important Notes](#cautions-and-important-notes)
    - [Customization](#customization)
    - [Verification](#verification)
  - [How to Use This Repository](#how-to-use-this-repository)
    - [Prerequisites](#prerequisites)
    - [Building a Custom Ubuntu ISO](#building-a-custom-ubuntu-iso)
    - [Building a Custom Debian ISO](#building-a-custom-debian-iso)

---

## Overview

This project is split into two main parts:

1.  **`Ubuntu-Autoinstall`**: Uses `cloud-init` for modern, automated installations of Ubuntu Server. The GRUB boot menu is customized to offer different installation strategies.
2.  **`Debian-Autoinstall`**: Uses the traditional `preseed` method for automating the Debian installer. The GRUB menu provides options for loading preseed files from local media or a remote server.

The goal is to provide flexible installation media that can handle different hardware and network scenarios without needing to build a new ISO for every case.

---

## Ubuntu Autoinstall

This configuration uses Ubuntu's `autoinstall` feature, which leverages `cloud-init` to configure the system. The bootloader menu (`grub.cfg`) is modified to present several autoinstall choices.

### Notable Options (Ubuntu)

When you boot from the custom Ubuntu ISO, you will see an "Autoinstall (Options)" submenu in GRUB with the following choices:

1.  **Autoinstall Default/HWE Kernel (auto)**:
    -   **Purpose**: A fully automated, "zero-touch" installation.
    -   **Behavior**: Uses the configuration files located in `/autoinstall/` on the ISO. It will automatically partition the disk and configure the network (assuming a DHCP server is present).
    -   **Use Case**: Ideal for deploying identical servers in a known environment.

2.  **Autoinstall Default/HWE Kernel (manual NIC + Disk)**:
    -   **Purpose**: A semi-automated installation where you manually configure networking and storage.
    -   **Behavior**: Uses configuration files from `/autoinstall/manual/`. The installer will stop and prompt you to select a network interface, configure IP settings, and choose the target disk for installation. All other steps (user creation, package installation, etc.) are automated.
    -   **Use Case**: Perfect for environments with multiple network cards, complex storage layouts, or no DHCP server.

> **Note**: Each option is available for both the standard **Default Kernel** and the **HWE (Hardware Enablement) Kernel** for broader hardware support.

### How It Works (Ubuntu)

The `grub.cfg` for Ubuntu defines the boot menu entries. For autoinstall, the key is the `linux` line, which passes specific kernel parameters to the installer.

For the **fully automated options** (e.g., "Autoinstall Default Kernel (auto)"), the `linux` line looks like this:
```
linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/autoinstall/ ---
```
-   `autoinstall`: This parameter signals the Ubuntu installer to initiate an automated installation.
-   `ds=nocloud`: Instructs `cloud-init` (which handles the autoinstall process) to use the "NoCloud" datasource. This means it looks for configuration files locally on the boot media.
-   `s=/cdrom/autoinstall/`: Specifies the directory on the ISO (`/cdrom/`) where `cloud-init` should find the `user-data` and `meta-data` files for the installation.

For the **semi-automated options** (e.g., "Autoinstall Default Kernel (manual NIC + Disk)"), the `linux` line is slightly different:
```
linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/autoinstall/manual/ ---
```
The crucial difference is `s=/cdrom/autoinstall/manual/`. This points `cloud-init` to a different set of `user-data` and `meta-data` files, which are specifically crafted to omit network and disk configuration, thereby prompting the user for these details during the installation process.

---


## Debian Autoinstall (Preseed)

This configuration uses Debian's `preseed` mechanism to answer the questions asked by the Debian installer.

### Notable Options (Debian)

The "Autoinstall (Options)" submenu in the Debian GRUB menu offers:

1.  **Autoinstall (DEFAULT-remote preseed)**:
    -   **Purpose**: Fully automated installation using a preseed file hosted on a web server.
    -   **Behavior**: Fetches `preseed.cfg` from `https://debian.ammonvargas.net/preseed.cfg`. Requires a working internet connection with DHCP at boot.
    -   **Use Case**: Deploying servers when you can ensure network connectivity from the start.

2.  **Autoinstall w NIC&DISK (local)**:
    -   **Purpose**: Semi-automated installation using a local preseed file.
    -   **Behavior**: Loads `preseed.cfg` from the root of the ISO. This file is configured to **skip** automatic network and disk configuration, forcing the installer to prompt you for those details.
    -   **Use Case**: The most flexible option for offline installations or when manual disk and network setup is required.

3.  **Autoinstall w NIC&DISK (remote)**:
    -   **Purpose**: Semi-automated installation using a remote preseed file.
    -   **Behavior**: Fetches `manual-preseed.cfg` from `https://debian.ammonvargas.net/manual-preseed.cfg`. This remote file is configured to prompt for network and disk setup.
    -   **Use Case**: Similar to the local manual option, but allows for centralized management of the preseed file.

### How It Works (Debian)

The `grub.cfg` for Debian also uses the `linux` line to pass parameters to the Debian Installer (`d-i`).

Common parameters across all autoinstall options include:
-   `auto=true priority=critical`: This tells the Debian Installer to run in fully automated mode, only stopping for questions that are not answered by the preseed file and are considered critical.
-   `DEBIAN_FRONTEND=text`: Ensures the installer runs in text mode, which is typical for server installations and preseed-based automation.

The key difference between the Debian autoinstall options lies in how the preseed file is located:

1.  **Autoinstall (DEFAULT-remote preseed)**:
    ```
    linux /install.amd/vmlinuz auto=true priority=critical preseed/url=https://debian.ammonvargas.net/preseed.cfg DEBIAN_FRONTEND=text vga=788 --- quiet
    ```
    Here, `preseed/url=https://debian.ammonvargas.net/preseed.cfg` instructs the installer to fetch the preseed file from a remote HTTP(S) server.

2.  **Autoinstall w NIC&DISK (local)**:
    ```
    linux /install.amd/vmlinuz auto=true priority=critical preseed/file=/cdrom/preseed.cfg DEBIAN_FRONTEND=text vga=788 --- quiet
    ```
    The `preseed/file=/cdrom/preseed.cfg` parameter tells the installer to load the preseed configuration directly from the root of the boot ISO. This `preseed.cfg` is specifically designed to prompt for network and disk details.

3.  **Autoinstall w NIC&DISK (remote)**:
    ```
    linux /install.amd/vmlinuz auto=true priority=critical preseed/url=https://debian.ammonvargas.net/manual-preseed.cfg DEBIAN_FRONTEND=text vga=788 --- quiet
    ```
    Similar to the default remote option, but `preseed/url=https://debian.ammonvargas.net/manual-preseed.cfg` points to a remote preseed file that is configured to allow manual network and disk setup.

The content of the specified `preseed.cfg` file (whether local or remote) then dictates the rest of the installation process by answering the `d-i` (Debian Installer) questions. For example, `d-i netcfg/disable_autoconfig boolean false` in your `preseed.cfg` explicitly allows the installer to prompt for network configuration.

---
## Cautions and Important Notes

<br>

> [!WARNING]
> **Destructive Operations**: The fully automated options for both Ubuntu and Debian are designed to **wipe the target disk without confirmation**. Use them with extreme caution and only on machines where you intend to erase all existing data.

> [!IMPORTANT]
> **Default Passwords**: The sample configuration files (`preseed.cfg`, `user-data`) contain insecure, hardcoded passwords (e.g., `weakkamogabos123`). These are for demonstration purposes only. **You must change these passwords before using the ISO in any real environment.**

> [!NOTE]
> **Network Dependency**: The remote preseed/autoinstall options require a reliable network connection with DHCP available at boot time. If the installer cannot get an IP address and reach the specified URL, the installation will fail or fall back to manual mode.

### Customization

-   For **Ubuntu**, modify the `user-data` and `meta-data` files in the `Ubuntu-Autoinstall/autoinstall/` directory to change packages, user accounts, or storage layouts.
-   For **Debian**, modify the `Debian-Autoinstall/sample-preseed.cfg` file to change the desired configuration. You can also use the `build.sh` script to generate a new one.

### Verification

Always test your custom ISOs in a virtual machine (like VirtualBox or QEMU) or on non-critical hardware before deploying them in a live environment.

---

## How to Use This Repository

Follow these steps to create your own custom bootable ISO.

### Prerequisites

You will need a Linux environment with the following tools installed:
- `xorriso`: For creating and modifying ISO images.
- `wget` or `curl`: For downloading the base ISO.

You can install these on a Debian/Ubuntu system with:
```bash
sudo apt-get update
sudo apt-get install -y xorriso wget
```

### Building a Custom Ubuntu ISO

1.  **Download Ubuntu Server ISO**: Get the official ISO you want to customize.
2.  **Mount the ISO**: Create a directory to mount the original ISO contents.
    ```bash
    mkdir -p /tmp/ubuntu-iso
    sudo mount -o loop path/to/ubuntu-server.iso /tmp/ubuntu-iso
    ```
3.  **Copy ISO Contents**: Copy the contents to a working directory where you can make changes.
    ```bash
    mkdir -p /tmp/ubuntu-new
    rsync -av /tmp/ubuntu-iso/ /tmp/ubuntu-new/
    ```
4.  **Copy Your Custom Files**: Copy the `autoinstall` directory and the modified `grub.cfg` into your new ISO structure.
    ```bash
    # Copy autoinstall configurations
    cp -r path/to/Ubuntu-Autoinstall/autoinstall /tmp/ubuntu-new/
    # Overwrite the GRUB configuration
    cp path/to/Ubuntu-Autoinstall/boot/grub/grub.cfg /tmp/ubuntu-new/boot/grub/grub.cfg
    ```
5.  **Generate the New ISO**: Use `xorriso` to create the new bootable ISO.
    ```bash
    sudo xorriso -as mkisofs -r \
      -V "Ubuntu-Autoinstall-Custom" \
      -o ubuntu-autoinstall-custom.iso \
      -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
      -boot-load-size 4 -boot-info-table \
      -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
      -isohybrid-gpt-basdat -isohybrid-apm-table \
      /tmp/ubuntu-new/
    ```

### Building a Custom Debian ISO

1.  **Download Debian Netinstall ISO**: Get the official network install ISO.
2.  **Mount the ISO**:
    ```bash
    mkdir -p /tmp/debian-iso
    sudo mount -o loop path/to/debian-netinst.iso /tmp/debian-iso
    ```
3.  **Copy ISO Contents**:
    ```bash
    mkdir -p /tmp/debian-new
    rsync -av /tmp/debian-iso/ /tmp/debian-new/
    ```
4.  **Copy Your Custom Files**:
    -   Use the `build.sh` script to generate a `preseed.cfg` or modify the `sample-preseed.cfg`.
    -   Copy the `preseed.cfg` to the root of the new ISO directory for the local install option.
    -   Overwrite the `grub.cfg`.
    ```bash
    # Copy your preseed file for the "local" install option
    cp path/to/Debian-Autoinstall/sample-preseed.cfg /tmp/debian-new/preseed.cfg
    # Overwrite the GRUB configuration
    cp path/to/Debian-Autoinstall/boot/grub.cfg /tmp/debian-new/boot/grub/grub.cfg
    ```
5.  **Generate the New ISO**:
    ```bash
    sudo xorriso -as mkisofs -r \
      -V "Debian-Preseed-Custom" \
      -o debian-preseed-custom.iso \
      -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
      -boot-load-size 4 -boot-info-table \
      -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
      -isohybrid-gpt-basdat -isohybrid-apm-table \
      /tmp/debian-new/
    ```

⚠️ **Destructive Operations**: The fully automated options for both Ubuntu and Debian are designed to wipe the target disk without confirmation. Use them with extreme caution and only on machines where you intend to erase all existing data.

🔒 **Default Passwords**: The Debian `preseed.cfg` file contains a hardcoded password (`weakkamogabos123`) for both the user and the remote SSH installer session. This is insecure and intended for development/testing only. **You must change these passwords before using the ISO in a production environment.**

🌐 **Network Dependency**: The remote preseed options for Debian require a reliable network connection with DHCP available at boot time. If the installer cannot get an IP address and reach the specified URL, the installation will fail or fall back to manual mode.

🔧 **Customization**:
-   For **Ubuntu**, modify the `user-data` files in the `autoinstall/` directory to change packages, user accounts, or storage layouts.
-   For **Debian**, modify the `preseed.cfg` file to change the desired configuration. You can also use the `build.sh` script to generate a new one.
