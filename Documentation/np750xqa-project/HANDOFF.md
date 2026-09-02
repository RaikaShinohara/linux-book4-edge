# Handoff to the next AI agent

## Objective

Continue the NP750XQA port. The kernel and recovery USB have been built and two
physical boots attempted. The next milestone is reliable early log capture
while testing real DP3 HPD and PMK8550 PWM backlight control.
Do not start by installing a desktop environment or writing Linux to internal
UFS.

## Work already completed

- Identified the machine as Samsung Galaxy Book4 Edge `NP750XQA-KB1ES`, system
  SKU `GALAXY A5A5-PVQA`, with an eight-core Snapdragon X Plus X1P42100.
- Captured and decompiled the Windows ACPI DSDT and captured the panel EDID.
- Selected `x1p42100.dtsi` plus `x1-crd.dtsi` as the base because firmware
  identifies the platform as `SCP_PURWA` / `CRD08380`.
- Added the new board compatible to the Qualcomm board binding.
- Added the NP750XQA DTS and its normal and EL2 Makefile targets.
- Enabled confirmed UFS regulators, UFS host and UFS PHY.
- Added the confirmed Samsung HID-over-I2C keyboard.
- Removed inherited CRD keyboard, touchpad and touchscreen nodes that do not
  describe this machine.
- Initially disabled native internal eDP and CAMSS rather than inheriting
  incorrect CRD devices. CAMSS remains disabled; eDP is now an explicit,
  experimental KDB implementation documented in `DISPLAY_BRINGUP.md`.
- Enabled UFSHCD, the Qualcomm UFS glue and QMP UFS PHY as built-in options in
  `book4_defconfig`.
- Added a theoretical support matrix to the repository root `README.md`.
- Built the complete kernel, modules and DTB with LLVM; see `BUILD_RECORD.md`.
- Created and validated an Arch Linux ARM recovery USB; see
  `USB_RECOVERY_RECORD.md`.
- Performed the first physical test. GRUB was visible, but the panel went black
  after Linux was selected and the delayed logger produced no files. See
  `FIRST_BOOT_RESULT.md` for the exact evidence and its limits.
- Replaced the inherited ATNA OLED node with a generic eDP panel for the KDB
  `KD156N2030A03`, enabled `mdss_dp3`, disabled unconfirmed ATNA backlight
  control and made the DRM, panel and eDP PHY drivers built in.
- Disabled the Adreno GPU for the first display test so missing 3D firmware
  cannot block the display-only MSM DRM path.
- The second physical attempt used a matched build with the display stack
  genuinely built in. Some Linux output appeared, then the screen went black;
  no saved log establishes whether boot continued. See `SECOND_BOOT_RESULT.md`.
- Compared the board with the upstream X1E HP OmniBook X14 and the X1P42100
  Surface Pro 12 community description. Replaced `no-hpd` with dedicated DP3
  HPD and described the PMK8550 19.2 kHz PWM backlight independently indicated
  by the Samsung DSDT.
- Added GRUB diagnostics for native display with firmware resources preserved,
  firmware framebuffer only, and firmware framebuffer with one CPU.
- Traced the recovery stick to ACPI `USB3/RHUB/MP1` and found that the CRD
  repeater topology could not describe this Samsung port. The board DTS now
  disables the inherited `i2c5:0x4f`/GPIO184 PTN3222 and connects
  `usb_mp_hsphy1` to `i2c18:0x4f`/GPIO7, matching the second USB3 ACPI
  repeater resource. See `USB_BRINGUP.md`.
- Made the complete USB-A root chain built in and corrected the recovery
  initramfs list to use `phy-nxp-ptn3222`. Added a default premount-shell GRUB
  entry with full early-userspace logging. These functional changes are commit
  `25c1771b1`.

## Validation already performed for the first boot artifact

- The DTS compiled with `dtc` 1.7.2.
- The DTB was decompiled again successfully for a semantic round trip.
- Assertions passed for model, compatible, UFS, UFS PHY, keyboard descriptor,
  disabled CAMSS, disabled internal eDP and removal of the wrong CRD inputs.
- DTB size: 213430 bytes.
- DTB SHA-256:
  `1287AEE365BB3C2FC88DEA9AD9677567677795D5C5D419D3449CC99D72650036`.
- Kernel `checkpatch.pl --strict` reported no problems for the board DTS or the
  ARM64 board document.
- Kconfig resolution confirmed these built-in settings:
  `CONFIG_SCSI_UFSHCD=y`, `CONFIG_SCSI_UFSHCD_PLATFORM=y`,
  `CONFIG_SCSI_UFS_QCOM=y`, `CONFIG_PHY_QCOM_QMP=y` and
  `CONFIG_PHY_QCOM_QMP_UFS=y`.

The build and schema validation recorded in `BUILD_RECORD.md` completed. The
DTB was boot-attempted on the physical machine, but there is not yet a kernel
log proving how far execution progressed.

## Validation performed for the previous display source

The new display DTB was preprocessed and compiled with `dtc` 1.7.2, then
decompiled successfully. Assertions confirmed enabled DP3, generic
`edp-panel`, retained panel supply and endpoint, `no-hpd`, removal of the ATNA
enable/pinctrl properties, and disabled GPU. Its size is 213348 bytes and its
SHA-256 is
`CC445BB69E707EC737E39EE3898CFA1A58022DF06FB0BF59443E9D2F579478D8`.
That exact DTB was part of the second physical attempt. It displayed some Linux
output and then became black, but no saved kernel log was recovered.

## Validation performed for the revised HPD/backlight source

Commit `65fe4cdbf3a52b6f01e5b806232fab8fe03619c7` was preprocessed and compiled
with `dtc` 1.7.2, then decompiled successfully. Assertions confirmed dedicated
DP3 HPD pinctrl, generic `edp-panel`, retained panel supply/endpoint, connected
`pwm-backlight`, enabled PMK8550 PWM, absent `no-hpd` and disabled GPU. Its size
is 213826 bytes and its SHA-256 is
`3317E3073D483911D7F985591E2D1AA26908DC65FFEE869520B97CFC56472057`.
This is structural validation only. The revised kernel has not been built on
Linux or tested on the physical machine.

## Immediate continuation order

1. Read `USB_BRINGUP.md`, build the current branch on the Arch workstation and
   confirm all seven USB-root Kconfig options plus the display/backlight
   options resolve to `y`.
2. Install the resulting Image, modules and DTB as one matched set on the
   removable recovery system; preserve the previous entries and artifacts.
3. Boot `NP750XQA USB-A premount shell (diagnostic)` first. Confirm PTN3222,
   XHCI and the external root device before typing `exit`.
4. Recover `/run/initramfs/init.log`, `dmesg` and persistent journal evidence
   before claiming UFS, keyboard or userspace support.
5. Then test the remaining GRUB entries in the order documented in
   `SECOND_BOOT_RESULT.md`.
6. If native video still fails, use the `nomodeset` comparison and DRM log to
   decide between HPD/AUX, link training and backlight rather than guessing a
   new GPIO.

## Hard constraints

- Do not claim hardware support without a log from this NP750XQA.
- Do not copy GPIOs, regulators, firmware names or panel data from the X1E
  Samsung board unless the NP750XQA evidence independently matches.
- Do not overwrite firmware, repartition internal UFS or install a default EFI
  boot entry without explicit user authorization.
- The first boot must use removable media and treat internal UFS as read-only.
- Preserve the Windows EFI entry and recovery media.
- Build on a case-sensitive Linux filesystem. The original Windows workspace
  was FAT32 and produced false Git modifications for case-colliding filenames;
  none of those false modifications were committed.
- Stop a physical test if fan, temperature, battery or power behaviour appears
  abnormal.
- Do not change the eight-CPU topology, PSCI method or select the EL2 overlay
  merely because video is black. First use the one-CPU diagnostic and recover
  logs. Firmware chooses EL1/EL2; there is no generic "disable hypervisor"
  kernel parameter.

## Reference repositories

- Kernel and X1E Samsung reference:
  <https://github.com/zensanp/linux-book4-edge>
- Samsung EC and platform research:
  <https://github.com/Saddytech/Galaxy-Book4-Edge-linux>

The second repository is useful research, but its EC driver and X1E board data
must not be assumed correct for this X1P42100 variant without verification.
