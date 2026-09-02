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

## Display-test update (2026-09-01)

The same positively identified and unmounted 8 GB removable device was updated
in place for the experimental display test. It was not repartitioned. The
previous kernel, DTB, initramfs and EFI loader were retained with a
`.firstboot` suffix and are selectable through the GRUB entry
`NP750XQA previous kernel (display disabled)`.

The repository GRUB template now also contains three diagnostic entries for
the next media update: native eDP with firmware resources preserved,
firmware-framebuffer-only using `nomodeset`, and the same framebuffer test with
one CPU and idle disabled. These entries have not been copied to the removable
drive in this Windows session. Their intended test order and interpretation are
in `SECOND_BOOT_RESULT.md`.

Installed display-test artifacts:

- `boot/Image-np750xqa` SHA-256:
  `0b96cc5dfb140f8fca37fb8c9fba723a593493cf28c4a409071ed030ef6fcfd3`
- display DTB SHA-256:
  `cc445bb69e707ec737e39ee3898cfa1a58022df06fb0bf59443e9d2f579478d8`
- `boot/initramfs-np750xqa.img` SHA-256:
  `6a03df5e38715f5172c3a1bca443413c8629d243a5c91911eba00e3e05999563`
- `EFI/BOOT/BOOTAA64.EFI` SHA-256:
  `d10561c49026b959edbcbac36cd1a72c125121a40e6d3585d4c806df7096cf95`

The embedded GRUB configuration enables `drm.debug=0x1ff`. The rebuilt
initramfs contains the explicit Qualcomm USB PHY, DWC3 and XHCI platform
modules. The 60-second logging delay is removed, `/var/log/journal` is enabled
for persistent journals and `/var/log/np750xqa` is created in advance.

## USB-A correction installed (2026-09-02)

The lack of logs is now treated as possible failure to reacquire the recovery
stick after the UEFI hand-off. The repository DTS replaces the inherited CRD
repeater association with the NP750XQA `i2c18:0x4f`/GPIO7 path. A second audit
found that the initial fix still left essential clock, pinctrl, regulator and
interconnect providers as modules, and omitted GPI DMA. `book4_defconfig` now
makes those providers and the complete USB-root chain built in. The mkinitcpio
template names the same provider chain defensively as well as the correct
`phy-nxp-ptn3222`, GENI I2C and Synopsys eUSB2 drivers.

The GRUB template defaults to a `break=premount` USB diagnostic with
`rd.log=all`. The diagnostic keyboard transports are built in, and the
first-boot logger copies the initramfs log to the external root after it mounts.
These changes were built natively on Arch and installed as one matched set on
the removable drive. The previous installed set is retained with the suffix
`.usbfix1`. The FAT and ext4 filesystems passed read-only checks after the
update.

- `boot/Image-np750xqa` SHA-256:
  `cf8c8a2c6615785cede360d5e01398dced2118ff03910c427087a85fb246a762`
- display/USB DTB SHA-256:
  `16cdcd18574c7c3d536ccfb0536c7e22dcecac0ad308bdbd3e823ee803d36c5e`
- `boot/initramfs-np750xqa.img` SHA-256:
  `326023d2da81d5eb49e87e1ef2517a66383433106b16190492dbab3174e88df2`
- `EFI/BOOT/BOOTAA64.EFI` SHA-256:
  `f0d63ed4da37c90e8d4ade4776f2c301b9eb6254e865eca06e2fe3f3b74cb79e`
- build configuration SHA-256:
  `5c3516e002186b331be5194b40b22f2ae5de516e5a86861fa5edc5d2eb44eed6`

The default embedded GRUB entry is the USB-A premount diagnostic. The
initramfs also contains `np750log`, which attempts to save early `dmesg`
snapshots on `NP750_EFI:/np750xqa-early-logs/`. Build instructions, expected
observations and the distinction between confirmed ACPI data and inferred port
pairing are in `USB_BRINGUP.md`.

## GRUB filesystem correction (2026-09-02)

The next physical test displayed GRUB correctly, but every entry failed before
loading Linux. GRUB reported that the valid NP750_ROOT UUID did not exist and
then could not open the kernel or DTB below `/boot`. No Linux log was produced.
This proves the LCD and firmware framebuffer path worked, while the kernel was
never entered.

To remove GRUB's dependency on reading ext4, the current kernel, initramfs and
DTB, plus the first-boot fallback set, are now mirrored under
`NP750_EFI:/np750xqa/`. All menu entries search for the FAT label `NP750_EFI`
and load their artifacts from that same partition. The Linux command line still
uses the unchanged NP750_ROOT UUID for the real root filesystem.

- rebuilt `EFI/BOOT/BOOTAA64.EFI` SHA-256:
  `32fe3dd858107b88a1077b5791da0ae48ef9ceea2c9aadde882cf697d74220e1`
