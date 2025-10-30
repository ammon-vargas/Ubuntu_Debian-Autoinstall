#!/bin/bash
# Validator-grade Debian Preseed Generator
# Author: Ammon-style interactive config builder

echo "### Debian Autoinstall Preseed Generator ###"
echo "--------------------------------------------"

# Locale and Keyboard
read -p "Enter locale (e.g., en_PH.UTF-8): " LOCALE
read -p "Enter keyboard layout (e.g., ph): " KEYMAP

# User Identity
read -p "Enter full name: " FULLNAME
read -p "Enter username: " USERNAME
read -s -p "Enter password: " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo

# Timezone
read -p "Enter timezone (e.g., Asia/Manila): " TIMEZONE

# Mirror
read -p "Enter mirror hostname (e.g., deb.debian.org): " MIRROR_HOST
read -p "Enter mirror directory (e.g., /debian): " MIRROR_DIR

# Output file
read -p "Enter output filename (e.g., preseed.cfg): " OUTPUT

# Generate file
cat <<EOF > "$OUTPUT"
### Debian Autoinstall Preseed Configuration ###

### Locale and Keyboard ###
d-i debian-installer/locale string $LOCALE
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select $KEYMAP

### Network Configuration (Manual NIC + IP Setup) ###
d-i netcfg/disable_autoconfig boolean false

### Installer Components ###
d-i anna/choose_modules string choose-mirror,fdisk-udeb,network-console,openssh-client-udeb,parted-udeb,rescue-mode

### Remote SSH Setup ###
d-i anna/choose_modules string network-console
d-i network-console/password password $PASSWORD
d-i network-console/password-again password $PASSWORD_CONFIRM

### Mirror Settings ###
d-i mirror/country string manual
d-i mirror/http/hostname string $MIRROR_HOST
d-i mirror/http/directory string $MIRROR_DIR
d-i mirror/http/proxy string

### User Setup ###
d-i passwd/root-login boolean false
d-i passwd/user-fullname string $FULLNAME
d-i passwd/username string $USERNAME
d-i passwd/user-password password $PASSWORD
d-i passwd/user-password-again password $PASSWORD_CONFIRM

### Timezone and Clock ###
d-i clock-setup/utc boolean true
d-i time/zone string $TIMEZONE
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string 0.debian.pool.ntp.org

### Partitioning (Manual Setup) ###
d-i partman-auto/method string
d-i partman/confirm boolean false
d-i partman/confirm_nooverwrite boolean false

### Base System ###
d-i base-installer/kernel/image string linux-image-amd64
d-i base-installer/initrd/include string all

### Package Manager ###
d-i apt-setup/services-select multiselect security updates, release updates
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true
d-i apt-setup/enable-source-repositories boolean true
d-i apt-setup/use_mirror boolean true
d-i apt-setup/mirror/country string manual
d-i apt-setup/mirror/http/hostname string $MIRROR_HOST
d-i apt-setup/mirror/http/directory string $MIRROR_DIR
d-i apt-setup/mirror/http/proxy string

### Software Selection ###
popularity-contest popularity-contest/participate boolean false
d-i pkgsel/update-policy select unattended-upgrades
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string curl htop net-tools

### GRUB Bootloader ###
d-i grub-installer/force-efi-extra-removable boolean false
d-i grub-installer/update-nvram boolean true
d-i grub-installer/with_other_os boolean false

### Finishing Up ###
d-i finish-install/reboot_in_progress note
EOF

echo "✅ Preseed file generated: $OUTPUT"