# NP750XQA USB-A root-device bring-up

## Why USB-A is now the first boot suspect

Both physical attempts reached Linux output and then produced neither a saved
initramfs log nor the userspace logger output. The recovery logger lives on the
same external root that Linux must enumerate, so its absence cannot distinguish
a display failure from failure to reacquire the USB stick after UEFI calls
`ExitBootServices`.

Windows PnP history places the Kingston `DT 101 II` recovery stick at
`ACPI(USB3)/RHUB/MP1`. `USB3` is `QCOM0D08` at `0x0a400000`, which maps to
`usb_mp_dwc3`. `MP1` is the USB 2.0 side of the second physical port and maps
to `usb_mp_hsphy1`. This old recovery stick therefore depends on the eUSB2
PHY and its external repeater even if the SuperSpeed PHY is unavailable.

The factory DSDT supplies two repeater resources to this controller:

- QUP `IC19`, physical address `0x00888000`; this is `i2c18` in Linux DT
  numbering, not `i2c19`;
- I2C addresses `0x43` and `0x4f`;
- TLMM reset GPIOs 6 and 7; and
- PMIC LDO4_B/LDO13_B, matching `vreg_l4b_1p8` and `vreg_l13b_3p0`.

The inherited CRD description instead put `eusb6_repeater` at `i2c5:0x4f`
with reset GPIO184. The board DTS now disables that device, creates an NXP
PTN3222 at `i2c18:0x4f` with reset GPIO7 and links it to
`usb_mp_hsphy1`. Pairing the second address/reset resource with the second PHY
is strongly supported by resource ordering and the ACPI port topology, but it
remains a hardware-test hypothesis until Linux logs the probe.

## Early-boot driver chain

The original initramfs named `phy-qcom-eusb2-repeater`, but an
`nxp,ptn3222` node is handled by `phy-nxp-ptn3222`. It also omitted the GENI
I2C controller and the Synopsys eUSB2 PHY modules. If those drivers are modules,
Linux can need the USB root in order to load the drivers needed to find that
same root.

`book4_defconfig` therefore requests the complete USB-root chain built in:

```text
CONFIG_I2C_QCOM_GENI=y
CONFIG_PHY_SNPS_EUSB2=y
CONFIG_PHY_NXP_PTN3222=y
CONFIG_PHY_QCOM_QMP_USB=y
CONFIG_USB_DWC3=y
CONFIG_USB_DWC3_QCOM=y
CONFIG_USB_XHCI_PLATFORM=y
```

USB storage, UAS, SCSI disk and ext4 were already built in. The recovery
mkinitcpio template also names all relevant modules explicitly so that it
remains useful if a future configuration changes any of them back to modules.

## Build and verify on Arch Linux

From the repository root on a case-sensitive filesystem:

```sh
make O=out ARCH=arm64 LLVM=1 book4_defconfig
make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" \
  qcom/x1p42100-samsung-galaxy-book4-edge.dtb Image modules

grep -E '^CONFIG_(I2C_QCOM_GENI|PHY_SNPS_EUSB2|PHY_NXP_PTN3222|PHY_QCOM_QMP_USB|USB_DWC3|USB_DWC3_QCOM|USB_XHCI_PLATFORM)=y$' \
  out/.config
```

The `grep` command must print all seven symbols. Then run the existing schema
checks and record SHA-256 hashes for `Image`, the DTB and `.config`. Install
the kernel, DTB and any remaining modules as one matched set. Rebuild the
initramfs using
`Documentation/np750xqa-project/recovery/mkinitcpio-np750xqa.conf`, and replace
the removable GRUB configuration with the repository template while retaining
the previous artifacts as a fallback.

Before booting, use `lsinitcpio` to confirm the initramfs was produced for the
new kernel release. A built-in driver will appear in the kernel rather than as
a `.ko` inside the archive; that is expected.

## First diagnostic entry

Boot `NP750XQA USB-A premount shell (diagnostic)` first. It uses `nomodeset`,
full mkinitcpio logging, disables USB autosuspend, tries the legacy USB
enumeration scheme first and requests `break=premount`. A shell should open
after early modules have loaded but before mkinitcpio mounts the external root.

If the screen remains visible, inspect:

```sh
cat /proc/cmdline
dmesg | grep -Ei 'usb|dwc3|xhci|eusb|ptn3222|i2c|scsi|sd '
ls -l /dev/sd* /dev/disk/by-uuid/
cat /run/initramfs/init.log
```

Expected evidence is a successful PTN3222 probe on `i2c@888000`, XHCI at
`0x0a400000`, a USB mass-storage device and the external root UUID. Type
`exit` to let mkinitcpio mount the root and continue. Because this entry stops
before mounting, an idle USB LED while sitting at its shell is normal.

If the screen still goes black, watch the recovery-stick LED. Activity that
resumes after the kernel starts is useful evidence that Linux reacquired the
port. No renewed activity, no `/dev/sd*`, or PTN3222/I2C probe errors point
back to the repeater association. Preserve `/run/initramfs/init.log`, `dmesg`
and the persistent journal whenever the root mounts.

## Boundaries

This revision does not prove that USB-A works and does not alter internal UFS.
It does not define the first `0x43`/GPIO6 repeater because that resource is
inferred to map to the other physical port and is not required to test the
known `MP1` recovery path. USB-C routing and its retimers remain a separate
unverified subsystem.
