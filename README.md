# QemuVirt-Setup
### Install Everything:

```
sudo pacman -Syu --noconfirm && \
sudo pacman -S --noconfirm qemu-full virt-manager libvirt dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft
```

### Enable and Start Services:
```
sudo systemctl enable --now libvirtd

```
### Add Your User to libvirt Group:

```
sudo usermod -aG libvirt $(whoami)
```

### Apply Group Changes:

```
newgrp libvirt
```

### Test:

```
virsh list --all
```

    Note: For GPU passthrough or advanced virtualization, also enable iommu in your GRUB settings.

##  UBUNTU/DEBIAN: QEMU + LIBVIRT + VIRT-MANAGER FULL SETUP
### Install Core Virtualization Stack:

```
sudo apt update && \
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils dnsmasq-utils

```
###  Enable libvirt:

```
sudo systemctl enable --now libvirtd
```


### Add User to Groups:

```
sudo adduser $(whoami) libvirt && \
sudo adduser $(whoami) libvirt-qemu
```

###  Apply Group Changes:

```
newgrp libvirt
```

###  Confirm It’s Working:

```
virsh list --all

```
    Tip for Ubuntu GUI users: You can launch virt-manager from Activities or run virt-manager in terminal to start managing VMs graphically.
