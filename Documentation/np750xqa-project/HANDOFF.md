# Handoff to the next AI agent

## Objective

Continue the NP750XQA port. The kernel and recovery USB have been built and a
first physical boot attempted. The next milestone is reliable early log
capture while testing the experimental internal KDB eDP implementation.
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

## Validation performed for the display source

The new display DTB was preprocessed and compiled with `dtc` 1.7.2, then
decompiled successfully. Assertions confirmed enabled DP3, generic
`edp-panel`, retained panel supply and endpoint, `no-hpd`, removal of the ATNA
enable/pinctrl properties, and disabled GPU. Its size is 213348 bytes and its
SHA-256 is
`CC445BB69E707EC737E39EE3898CFA1A58022DF06FB0BF59443E9D2F579478D8`.
This DTB has not been physically tested, and a complete kernel has not been
built from the display branch on this Windows machine.

## Immediate continuation order

1. Extend logging into initramfs/early userspace so it syncs incremental
   evidence to the removable root. The 60-second delay was removed from the
   recovery service, but that service still depends on reaching userspace.
2. Enable persistent journald storage for later userspace evidence.
3. Repeat the removable-media test and recover logs before claiming UFS,
   keyboard or userspace support.
4. Rebuild from the display branch, update the removable kernel and DTB as a
   matched pair, and test whether the KDB EDID is read over AUX.
5. If video appears but brightness control does not, capture DRM and backlight
   sysfs evidence before adding any PWM or GPIO assumption.

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
