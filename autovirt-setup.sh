#!/bin/bash
#
# QemuVirt-Setup - Automated QEMU/KVM Virtualization Setup for Arch Linux
#
# This script transforms your Arch Linux system into a complete virtualization
# environment by installing and configuring QEMU, libvirt, virt-manager, and
# all necessary components. Perfect for malware analysis, red teaming, OS
# sandboxing, and Windows VM optimization with SPICE, VirtIO, and UEFI support.
#
# Features:
# - Installs complete virtualization stack (QEMU, libvirt, virt-manager, SPICE, OVMF)
# - Resolves iptables conflicts by switching to nftables
# - Configures KVM modules for Intel/AMD processors
# - Sets up libvirt networking and user permissions
# - Enables UEFI boot support for Windows guests
# - Fully automated setup - just run and reboot
#
# Requirements:
# - Arch Linux (or derivatives like Manjaro/EndeavourOS)
# - sudo privileges
# - Active internet connection
#
# Usage: sudo ./autovirt-setup.sh
#
# Author: https://github.com/cxb3rf1lth/QemuVirt-Setup
#

set -e

echo "[*] Updating system..."
sudo pacman -Syu --noconfirm

echo "[*] Checking iptables conflict..."
if pacman -Qs '^iptables$' > /dev/null; then
  echo "[!] Conflict: legacy iptables is installed and blocks iptables-nft"
  echo "[*] Forcing switch to iptables-nft..."

  echo "[*] Removing iptables (forcefully)..."
  sudo pacman -Rdd --noconfirm iptables

  echo "[*] Installing iptables-nft with overwrite..."
  sudo pacman -S --noconfirm --overwrite="*" iptables-nft

  echo "[*] Reinstalling iproute2 to fix shared lib dependency..."
  sudo pacman -S --noconfirm iproute2
fi

echo "[*] Installing virtualization stack..."
sudo pacman -S --noconfirm qemu-full virt-manager libvirt dnsmasq vde2 bridge-utils openbsd-netcat ebtables \
  spice-gtk spice-protocol swtpm edk2-ovmf virt-viewer ovmf usbredir virtiofsd virtio-win

echo "[*] Enabling libvirtd..."
sudo systemctl enable --now libvirtd

echo "[*] Adding current user to libvirt/kvm groups..."
sudo usermod -aG libvirt,kvm $(whoami)

echo "[*] Loading KVM modules..."
echo -e "kvm\nkvm_intel\nkvm_amd" | sudo tee /etc/modules-load.d/kvm.conf > /dev/null

echo "[*] Configuring default libvirt network..."
sudo virsh net-autostart default || true
sudo virsh net-start default || true

echo "[*] Enabling OVMF UEFI bootloader for Windows guests..."
if ! grep -q 'nvram' /etc/libvirt/qemu.conf; then
  sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak
  sudo sed -i 's|#nvram =.*|nvram = ["/usr/share/edk2/x64/OVMF_CODE.fd:/usr/share/edk2/x64/OVMF_VARS.fd"]|' /etc/libvirt/qemu.conf
fi

echo "[*] Reloading libvirtd to apply changes..."
sudo systemctl restart libvirtd

echo "[✔] DONE. You are now virtualization war-ready on Arch."
echo "⚠  Reboot or re-login for group changes to apply."
echo "💡 Launch 'virt-manager' to build your VMs with SPICE, VirtIO, and UEFI."

