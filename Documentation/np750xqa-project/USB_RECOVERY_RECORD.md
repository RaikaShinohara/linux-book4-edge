# NP750XQA USB recovery-media record

The recovery medium was prepared on 2026-08-31 for the first physical
NP750XQA boot test.

## Destructive target identification

- Whole disk: `/dev/sdd`
- USB model observed immediately before repartitioning: `DT 101 II`
- Capacity: 8,021,606,400 bytes (7.47 GiB)
- Transport/removable flags: USB, removable
- Previous contents: Fedora Workstation live image
- User explicitly authorized erasing the complete `/dev/sdd` device

The previous image was replaced by a GPT containing:

- `/dev/sdd1`: 512 MiB EFI System Partition, FAT32, label `NP750_EFI`,
  UUID `2A8E-8A5D`
- `/dev/sdd2`: remaining 7 GiB Linux filesystem, ext4, label
  `NP750_ROOT`, UUID `c2bc9dc2-bdf2-4d87-9225-7c0b6d44a52e`

## System source

The root filesystem is the Arch Linux ARM generic AArch64 rootfs published on
2026-08-05.

- Archive SHA-256:
  `42a4eeaa038994ffd31fa173256ef2f0ef511358eeb41b9ea1f8626391b9b319`
- Published MD5 matched:
  `23eec86365b24f7913c403e8f4e8719b`
- The detached signature was verified with Arch Linux ARM build-system key
  `68B3537F39A313B3E574D06777193F152BDBE6A6`.

The AArch64 GRUB package is `grub` 2:2.14-1.1 from Arch Linux ARM.

- Package SHA-256:
  `cf8470867afde66260a1e59d32ea186cd3493513c785a18a3b0f8b8aacab269c`
- Its detached package signature was verified with the same build-system key.

## Installed boot artifacts

- Fallback EFI loader: `EFI/BOOT/BOOTAA64.EFI`, SHA-256
  `bef4b2411c8bb0d2b9c722a16e258cc7e9006460411802358af8b8e9a92e4e56`
- Kernel: `boot/Image-np750xqa`, SHA-256
  `f911a6f8a209d75387ac2881b0e160d102a4cc5e25fb3de398941b4a7cb90a1e`
- Board DTB: `boot/x1p42100-samsung-galaxy-book4-edge.dtb`, SHA-256
  `1287aee365bb3c2fc88dea9ad9677567677795d5c5d419d3449cc99d72650036`
- Initramfs: `boot/initramfs-np750xqa.img`, SHA-256
  `5190487ecd4a7bef3d0a2ed5572b11bf264bf2f6dd71986405d84e818a084612`

The initramfs was generated inside the AArch64 root using QEMU user-mode
emulation. It explicitly includes the Qualcomm DWC3, XHCI platform, QMP combo,
QMP USB-C and EUSB2 repeater modules. The temporary QEMU executable was removed
from the installed root afterward.

GRUB uses the removable-media fallback filename and an embedded configuration.
It loads the exact kernel, initramfs and NP750XQA DTB from the external ext4
filesystem. The root command line uses `ro rootwait`; only the external root
UUID is selected.

## Safety configuration

- No internal-UFS partition appears in `fstab` or the GRUB command line.
- The ESP is listed as `noauto,ro`.
- SSH and systemd-networkd are masked for the first boot.
- Native internal display is disabled in the DTB recorded here. A later
  display-branch DTB is not yet installed on this medium.
- A one-shot service stores first-boot diagnostics under
  `/var/log/np750xqa/` on the external root.
- No firmware file, internal UFS sector, Windows EFI entry or laptop firmware
  setting was modified while creating the medium.

Secure Boot must be disabled for this experimental first boot because GRUB
does not allow its `devicetree` command while lockdown is enforced. Select the
USB only from the laptop's one-time firmware boot menu.
