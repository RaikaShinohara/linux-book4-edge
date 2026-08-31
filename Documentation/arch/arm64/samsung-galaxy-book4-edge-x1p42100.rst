.. SPDX-License-Identifier: GPL-2.0

=======================================================
Samsung Galaxy Book4 Edge NP750XQA (Snapdragon X Plus)
=======================================================

This document describes the initial Linux bring-up for the Samsung Galaxy
Book4 Edge NP750XQA with the Qualcomm Snapdragon X Plus X1P42100.

Hardware identification
=======================

The firmware on the investigated ``NP750XQA-KB1ES`` reports:

* system SKU ``GALAXY A5A5-PVQA``;
* Qualcomm platform identity ``SCP_PURWA`` and ``CRD08380``;
* an eight-core Snapdragon X Plus X1P42100 with an Adreno X1-45 GPU;
* 16 GiB of RAM;
* a 256 GB Kioxia ``THGJFJT1E45BATPA`` UFS device;
* a KDB ``KD156N2030A03`` 1920x1080 internal panel;
* a FastConnect 7800 WLAN device at PCI ID ``17cb:1107``;
* a Samsung ``SSEC0001`` HID-over-I2C keyboard; and
* a Zinitix ``ZNT0001`` HID-over-I2C touchpad.

The ACPI DSDT and panel EDID were captured from Windows before writing the
initial Device Tree. Machine-unique identifiers are not part of this tree.

Device Tree baseline
====================

The board includes ``x1p42100.dtsi`` and ``x1-crd.dtsi`` because its firmware
identifies it as a Purwa/X1P42100 CRD derivative. It does not use the X1E80100
Samsung board as its base.

The initial Device Tree provides:

* the NP750XQA model and compatible strings;
* the internal UFS controller, PHY and confirmed regulator assignments; and
* the keyboard at I2C address ``0x05``, HID descriptor address ``0x20`` and
  TLMM interrupt 67.

The keyboard interrupt mapping is supported by the matching Samsung ACPI GPIO
resource and the existing X1E80100 Galaxy Book4 Edge Device Tree.

Deliberately deferred hardware
==============================

The following devices remain disabled or undescribed until their board data is
confirmed:

* The internal panel is not the ATNA panel from ``x1-crd.dtsi``. The inherited
  eDP controller therefore remains disabled.
* The CRD camera sensor does not describe the NP750XQA camera path, so CAMSS is
  disabled.
* The touchpad is present at I2C address ``0x40`` on ``i2c13``. Its HID
  descriptor address is supplied through the runtime ACPI NVS byte ``TPDO``;
  it must not be guessed.
* The X1E Samsung UFS reset GPIO is not used until it is confirmed on this
  board.
* Audio, the Samsung embedded controller, battery reporting and platform
  profile integration need hardware testing.

Build on Arch Linux
===================

Install the native LLVM kernel build dependencies::

    sudo pacman -S --needed base-devel bc bison cpio dtc flex git llvm lld \
        openssl pahole python

Configure and build the Device Tree from the root of the kernel repository::

    make O=out ARCH=arm64 LLVM=1 book4_defconfig
    make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" \
        qcom/x1p42100-samsung-galaxy-book4-edge.dtb

The resulting blob is::

    out/arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dtb

Build the kernel and modules with the same configuration::

    make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" Image modules

``book4_defconfig`` builds the UFS host, Qualcomm UFS glue and QMP UFS PHY into
the kernel so a recovery initramfs can discover internal storage without those
drivers already being available as modules.

Initial boot policy
===================

The first hardware test should use a removable, recoverable boot path and an
initramfs with a shell. Preserve the Windows EFI entry and recovery media. Do
not repartition UFS, overwrite firmware or make the experimental kernel the
default boot entry until early console and storage logs have been reviewed.

The most useful first report is the complete early console and ``dmesg`` log,
including UFS, GENI I2C, HID, PCIe, remoteproc and display probe messages.
