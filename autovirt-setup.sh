#!/bin/bash
#
# ZedVirt Auto-Installer for Arch Linux
# Description: Automated QEMU/KVM virtualization setup script
# Author: cxb3rf1lth
# Version: 2.0
# License: MIT
# 
# This script transforms your Arch Linux system into a QEMU/KVM virtualization
# powerhouse with SPICE, VirtIO, and UEFI support for optimal VM performance.
#
# Requirements:
# - Arch Linux (or derivative)
# - sudo privileges
# - Internet connection
# - Hardware virtualization support (Intel VT-x or AMD-V)
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running on Arch Linux
check_arch_linux() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script requires Arch Linux with pacman package manager"
        exit 1
    fi
    
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/manjaro-release ]] && [[ ! -f /etc/endeavouros-release ]]; then
        log_warning "Not detected as Arch Linux. Proceeding anyway..."
    fi
}

# Function to check hardware virtualization support
check_virtualization_support() {
    log_info "Checking hardware virtualization support..."
    
    if ! egrep -q '(vmx|svm)' /proc/cpuinfo; then
        log_error "Hardware virtualization not supported or not enabled in BIOS"
        log_error "Please enable Intel VT-x or AMD-V in your BIOS settings"
        exit 1
    fi
    
    log_success "Hardware virtualization support detected"
}

# Function to confirm destructive operations
confirm_operation() {
    read -p "This script will modify your system and install virtualization packages. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
}

# Main execution starts here
main() {
    log_info "Starting ZedVirt Auto-Installer..."
    
    # Pre-flight checks
    check_arch_linux
    check_virtualization_support
    confirm_operation
    
    log_info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Handle iptables conflict
    log_info "Checking for iptables conflicts..."
    if pacman -Qs '^iptables$' > /dev/null; then
        log_warning "Legacy iptables detected - switching to iptables-nft for compatibility"
        
        log_info "Removing legacy iptables..."
        sudo pacman -Rdd --noconfirm iptables
        
        log_info "Installing iptables-nft..."
        sudo pacman -S --noconfirm --overwrite="*" iptables-nft
        
        log_info "Reinstalling iproute2 to fix dependencies..."
        sudo pacman -S --noconfirm iproute2
        
        log_success "Successfully switched to iptables-nft"
    else
        log_success "No iptables conflicts detected"
    fi
    
    # Install virtualization stack
    log_info "Installing QEMU/KVM virtualization stack..."
    sudo pacman -S --noconfirm \
        qemu-full \
        virt-manager \
        libvirt \
        dnsmasq \
        vde2 \
        bridge-utils \
        openbsd-netcat \
        ebtables \
        spice-gtk \
        spice-protocol \
        swtpm \
        edk2-ovmf \
        virt-viewer \
        ovmf \
        usbredir \
        virtiofsd \
        virtio-win || {
        log_error "Failed to install virtualization packages"
        exit 1
    }
    
    log_success "Virtualization packages installed successfully"
    
    # Configure services
    log_info "Enabling and starting libvirtd service..."
    sudo systemctl enable --now libvirtd
    
    if sudo systemctl is-active --quiet libvirtd; then
        log_success "libvirtd service is running"
    else
        log_error "Failed to start libvirtd service"
        exit 1
    fi
    
    # Configure user groups
    log_info "Adding user $(whoami) to libvirt and kvm groups..."
    sudo usermod -aG libvirt,kvm "$(whoami)"
    log_success "User groups configured"
    
    # Load KVM modules
    log_info "Configuring KVM kernel modules..."
    echo -e "kvm\nkvm_intel\nkvm_amd" | sudo tee /etc/modules-load.d/kvm.conf > /dev/null
    
    # Load modules immediately
    sudo modprobe kvm 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true  
    sudo modprobe kvm_amd 2>/dev/null || true
    
    log_success "KVM modules configured"
    
    # Configure default network
    log_info "Configuring default libvirt network..."
    sudo virsh net-autostart default 2>/dev/null || true
    sudo virsh net-start default 2>/dev/null || true
    
    if sudo virsh net-list --all | grep -q "default.*active"; then
        log_success "Default network configured and active"
    else
        log_warning "Default network may need manual configuration"
    fi
    
    # Configure OVMF UEFI
    log_info "Configuring OVMF UEFI bootloader for modern VMs..."
    if [[ ! -f /etc/libvirt/qemu.conf.bak ]]; then
        sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak
        log_info "Backup created: /etc/libvirt/qemu.conf.bak"
    fi
    
    if ! grep -q 'nvram.*OVMF' /etc/libvirt/qemu.conf; then
        sudo sed -i 's|#nvram =.*|nvram = ["/usr/share/edk2/x64/OVMF_CODE.fd:/usr/share/edk2/x64/OVMF_VARS.fd"]|' /etc/libvirt/qemu.conf
        log_success "OVMF UEFI configured"
    else
        log_success "OVMF UEFI already configured"
    fi
    
    # Download VirtIO drivers
    download_virtio_drivers
    
    # Restart libvirtd to apply configuration changes
    log_info "Restarting libvirtd to apply configuration changes..."
    sudo systemctl restart libvirtd
    
    if sudo systemctl is-active --quiet libvirtd; then
        log_success "libvirtd restarted successfully"
    else
        log_error "Failed to restart libvirtd"
        exit 1
    fi
    
    # Final verification
    perform_final_verification
    
    # Installation complete
    echo
    log_success "================== INSTALLATION COMPLETE =================="
    echo
    log_info "🎉 Your Arch Linux system is now a virtualization powerhouse!"
    echo
    log_warning "⚠️  IMPORTANT: You must log out and log back in for group changes to take effect"
    echo
    log_info "🚀 Next steps:"
    log_info "   1. Log out and log back in (or reboot)"
    log_info "   2. Launch 'virt-manager' to create VMs"
    log_info "   3. Use UEFI boot for modern Windows guests"
    log_info "   4. VirtIO drivers available at: /var/lib/libvirt/images/virtio-win.iso"
    echo
    log_info "📖 For troubleshooting and advanced usage, see the README"
    echo
}

# Function to download VirtIO drivers
download_virtio_drivers() {
    local virtio_dir="/var/lib/libvirt/images"
    local virtio_url="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
    local virtio_path="$virtio_dir/virtio-win.iso"
    
    log_info "Downloading VirtIO drivers for Windows guests..."
    
    # Create directory if it doesn't exist
    sudo mkdir -p "$virtio_dir"
    
    # Check if already downloaded
    if [[ -f "$virtio_path" ]]; then
        log_info "VirtIO drivers already present at $virtio_path"
        return 0
    fi
    
    # Download VirtIO ISO
    if command -v curl &> /dev/null; then
        sudo curl -L -o "$virtio_path" "$virtio_url" || {
            log_warning "Failed to download VirtIO drivers. You can download manually from:"
            log_warning "$virtio_url"
            return 1
        }
    elif command -v wget &> /dev/null; then
        sudo wget -O "$virtio_path" "$virtio_url" || {
            log_warning "Failed to download VirtIO drivers. You can download manually from:"
            log_warning "$virtio_url"
            return 1
        }
    else
        log_warning "Neither curl nor wget available. Install one to auto-download VirtIO drivers"
        log_info "Manual download: $virtio_url"
        return 1
    fi
    
    if [[ -f "$virtio_path" ]]; then
        log_success "VirtIO drivers downloaded to $virtio_path"
        sudo chmod 644 "$virtio_path"
    else
        log_warning "VirtIO driver download may have failed"
    fi
}

# Function to perform final verification
perform_final_verification() {
    log_info "Performing final verification..."
    
    # Check services
    if sudo systemctl is-active --quiet libvirtd; then
        log_success "✓ libvirtd service is active"
    else
        log_error "✗ libvirtd service is not active"
    fi
    
    # Check KVM modules
    if lsmod | grep -q kvm; then
        log_success "✓ KVM modules loaded"
    else
        log_warning "⚠ KVM modules not loaded (may load on reboot)"
    fi
    
    # Check default network
    if sudo virsh net-list --all 2>/dev/null | grep -q "default.*active"; then
        log_success "✓ Default network is active"
    else
        log_warning "⚠ Default network status unknown"
    fi
    
    # Check OVMF files
    if [[ -f /usr/share/edk2/x64/OVMF_CODE.fd ]] && [[ -f /usr/share/edk2/x64/OVMF_VARS.fd ]]; then
        log_success "✓ OVMF UEFI firmware available"
    else
        log_warning "⚠ OVMF UEFI firmware files not found"
    fi
    
    # Check group membership
    if groups "$(whoami)" | grep -q libvirt; then
        log_success "✓ User is in libvirt group"
    else
        log_warning "⚠ User group changes pending (requires logout/login)"
    fi
}

# Execute main function
main "$@"

