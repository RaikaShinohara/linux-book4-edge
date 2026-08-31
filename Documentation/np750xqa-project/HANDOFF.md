# Handoff to the next AI agent

## Objective

Continue the NP750XQA port on the user's Arch Linux x86-64 workstation. The
next milestone is a reproducible ARM64 kernel build and a non-destructive
recovery boot that produces complete logs. Do not start by installing a
desktop environment or writing Linux to internal UFS.

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
- Disabled native internal eDP and CAMSS until the Samsung-specific hardware
  description is known.
- Enabled UFSHCD, the Qualcomm UFS glue and QMP UFS PHY as built-in options in
  `book4_defconfig`.
- Added a theoretical support matrix to the repository root `README.md`.

## Validation already performed

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

The complete kernel was not built and the DTB was not booted on the physical
machine.

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

## Reference repositories

- Kernel and X1E Samsung reference:
  <https://github.com/zensanp/linux-book4-edge>
- Samsung EC and platform research:
  <https://github.com/Saddytech/Galaxy-Book4-Edge-linux>

The second repository is useful research, but its EC driver and X1E board data
must not be assumed correct for this X1P42100 variant without verification.
