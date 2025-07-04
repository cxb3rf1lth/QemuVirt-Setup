# 🧨 ZedVirt Arch Hypervisor Auto-Installer

**ZedVirt** is a full-spectrum, automated Arch Linux script that transforms your system into a QEMU/KVM virtualization powerhouse — perfect for malware analysis, red teaming, OS sandboxing, and Windows VM optimization with SPICE, VirtIO, and UEFI support.

---

## 🚀 Features

- ✅ Installs QEMU, libvirt, virt-manager, SPICE, and OVMF
- ✅ Fixes `iptables` conflicts cleanly by switching to nftables
- ✅ Loads KVM modules for Intel/AMD
- ✅ Enables libvirt daemon and default network
- ✅ Adds user to `libvirt` and `kvm` groups
- ✅ Sets UEFI (OVMF) boot for Windows guests
- ✅ Downloads VirtIO ISO (optional) for guest drivers
- ✅ Fully unattended — reboot and build VMs immediately

---

## ⚙️ Requirements

- Arch Linux (or derivative like Manjaro/EndeavourOS)
- sudo access
- Network connection

---

## 🛠️ Installation

```bash
git clone 
cd zedvirt-installer
chmod +x autovirt-setup.sh
./zedvirt-install.sh

