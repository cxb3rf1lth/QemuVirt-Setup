#  Qemu-full Arch Hypervisor Auto-Installer

**ZedVirt** is a full-spectrum, automated Arch Linux script that transforms your system into a QEMU/KVM virtualization powerhouse — perfect for malware analysis, red teaming, OS sandboxing, and Windows VM optimization with SPICE, VirtIO, and UEFI support.

---

## Features

-  **Comprehensive Installation**: QEMU, libvirt, virt-manager, SPICE, and OVMF
-  **Smart Conflict Resolution**: Fixes `iptables` conflicts by switching to nftables
-  **Hardware Optimization**: Loads KVM modules for Intel/AMD processors
-  **Service Management**: Enables libvirt daemon and default network
-  **User Configuration**: Adds user to `libvirt` and `kvm` groups
-  **Modern Boot Support**: Sets UEFI (OVMF) boot for Windows guests
-  **Driver Integration**: Downloads VirtIO ISO for optimal guest performance
-  **Validation & Verification**: Pre-flight checks and post-installation validation
-  **User-Friendly**: Interactive confirmations and colored output
-  **Error Handling**: Robust error detection and graceful failure handling

---

##  Requirements

**System Requirements:**
- Arch Linux (or derivative like Manjaro/EndeavourOS/Artix)
- Hardware virtualization support (Intel VT-x or AMD-V)
- Minimum 4GB RAM (8GB+ recommended)
- At least 20GB free disk space

**Permissions & Network:**
- sudo/root access
- Active internet connection for package downloads
- BIOS/UEFI virtualization enabled

---

## Installation

```bash
cd Desktop 
git clone https://github.com/cxb3rf1lth/QemuVirt-Setup.git
cd QemuVirt-Setup
chmod +x autovirt-setup.sh

# View help information
./autovirt-setup.sh --help

# Run the installer
sudo ./autovirt-setup.sh
```

### Script Options

- `--help` or `-h`: Display help information and usage
- `--version` or `-v`: Show version information

---

## Usage

After installation, you can start managing virtual machines:

1. **Launch virt-manager**: `virt-manager` (GUI for VM management)
2. **Command line tools**: Use `virsh` for command-line VM management
3. **Reboot recommended**: Log out and back in for group permissions to take effect

### Creating Your First VM

1. Open `virt-manager`
2. Click "Create a new virtual machine"
3. Select your installation method (ISO image, network install, etc.)
4. Configure VM settings:
   - **OS Type**: Choose your guest OS
   - **Memory & CPU**: Allocate resources
   - **Storage**: Create virtual disk
   - **Network**: Default NAT network is pre-configured

### VirtIO Drivers

For optimal Windows guest performance, VirtIO drivers are included:
- **Storage**: VirtIO Block for faster disk I/O
- **Network**: VirtIO Network for better networking performance
- **Graphics**: SPICE for enhanced display and USB redirection
- **Memory**: Balloon driver for dynamic memory management

---

## Post-Installation Verification

Verify your installation with these commands:

```bash
# Check if services are running
sudo systemctl status libvirtd

# Verify KVM modules are loaded
lsmod | grep kvm

# Check if you're in the correct groups
groups | grep -E "(libvirt|kvm)"

# Test default network
sudo virsh net-list --all
```

---

## Troubleshooting

### Common Issues

**Issue**: Permission denied when creating VMs
```bash
# Solution: Ensure you're in the libvirt group and have logged out/in
groups | grep libvirt
# If not in group, run: sudo usermod -aG libvirt $(whoami)
# Then logout and login again
```

**Issue**: KVM not available
```bash
# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0. If 0, enable virtualization in BIOS
```

**Issue**: Network connectivity problems
```bash
# Restart default network
sudo virsh net-destroy default
sudo virsh net-start default
```

**Issue**: UEFI boot not available
```bash
# Verify OVMF installation
ls /usr/share/edk2/x64/OVMF_*.fd
# Should show OVMF_CODE.fd and OVMF_VARS.fd
```

---

## Security Considerations

- **Isolation**: VMs provide strong isolation but are not 100% secure
- **Network**: Default NAT network isolates VMs from host network
- **Resources**: Monitor resource usage to prevent host system impact
- **Updates**: Keep host system and guest VMs updated
- **Snapshots**: Use VM snapshots before testing potentially harmful software

---

## Supported Distributions

**Primary Support:**
- Arch Linux
- Manjaro
- EndeavourOS
- Artix Linux

**Requirements:**
- `pacman` package manager
- `systemd` init system (for service management)
- Hardware virtualization support (Intel VT-x or AMD-V)

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with a clear description

### Reporting Issues

Please include:
- Distribution and version
- Error messages or logs
- Steps to reproduce the issue

---

## License

This project is released under the MIT License. See the repository for full license details.

---

## Acknowledgments

- **QEMU/KVM** - The virtualization foundation
- **libvirt** - Virtualization API and management
- **Arch Linux** - The target platform
- **VirtIO** - Paravirtualized drivers for performance
