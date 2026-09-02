# Second physical boot result and revised display hypothesis

## Observed result

The kernel and DTB built from commit `ba45a7e703197cbf15d6a8b1ecafebd9f27306cd`
were tested on the physical NP750XQA. The display showed a small amount of
Linux boot output and then became black, as in the previous attempt. No saved
kernel log or photograph containing readable final messages is available in
this repository, so it is not known whether userspace subsequently started.

That commit made the complete MSM DRM, generic eDP panel and Qualcomm eDP PHY
stack built in. The repeated black screen therefore cannot be explained only
by those drivers having been modules. The visible Linux text proves that UEFI
entered the kernel, but it does not prove UFS, the external root or userspace.

Subsequent inspection made USB-root failure a concrete competing explanation.
The tested Kingston stick was connected at ACPI `USB3/RHUB/MP1`, while the DTS
used the X1 CRD's wrong eUSB2 repeater bus/reset and the initramfs omitted the
actual NXP PTN3222 driver. See `USB_BRINGUP.md`. The next test must establish
USB enumeration before drawing any new conclusion from the black panel.

## Display comparison

Working Qualcomm X1 LCD descriptions were compared with this board:

- the upstream X1E HP OmniBook X14 and the X1P42100 Surface Pro 12 community
  port use the dedicated DP3 HPD pinctrl state and do not set `no-hpd`;
- both describe a generic `edp-panel` below the DP3 AUX bus;
- both use a PMK8550 PWM for LCD backlight control;
- the NP750XQA factory DSDT independently reports active-high eDP HPD and PMIC
  PWM backlight control at 19.2 kHz with 9-bit resolution.

The previous Samsung DTS contradicted the first point by setting `no-hpd` and
did not describe the PWM path. Commit
`65fe4cdbf3a52b6f01e5b806232fab8fe03619c7` now:

1. assigns `edp0_hpd_default` to `mdss_dp3`;
2. removes `no-hpd` from the panel;
3. enables the PMK8550 PWM on PMIC GPIO 5 function 3;
4. connects a 19.2 kHz, 9-bit `pwm-backlight` to the panel; and
5. builds both the PWM backlight and Qualcomm LPG/PWM provider into the kernel.

The inherited CRD panel 3.3 V rail remains the main board-level assumption.
No unconfirmed backlight-enable GPIO was added.

References:

- <https://github.com/torvalds/linux/blob/master/arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi>
- <https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/display/panel/panel-edp.yaml>
- <https://github.com/harrisonvanderbyl/surface-pro-12-inch-linux>

## CPU and hypervisor review

`x1p42100.dtsi` intentionally removes CPU nodes 8 through 11 and the third
cluster inherited from X1E80100, leaving the expected eight CPUs. The remaining
CPUs use standard PSCI startup. Nothing in the board DTS currently overrides
that topology.

The normal DTB is the correct first choice for the usual firmware hand-off at
EL1 under Gunyah. The optional `-el2` overlay changes GPU/PCIe IOMMU ownership
and watchdog state; it does not alter CPU enable methods or the internal display
path. The exception level is selected by firmware, so there is no safe kernel
command-line switch that simply "skips the hypervisor".

The recovery GRUB template now defaults to an earlier diagnostic using
`nomodeset`, `break=premount`, full mkinitcpio logging and conservative USB
parameters. It must prove the external USB device before root mount.

The three display/CPU diagnostics remain available:

1. native eDP while preserving firmware-enabled clocks, power domains and
   regulators;
2. `nomodeset`, which keeps native MSM DRM out of the hand-off and tests whether
   the firmware framebuffer remains usable; and
3. `nomodeset maxcpus=1 cpuidle.off=1`, which additionally isolates secondary
   CPU startup and idle states.

Interpretation:

- If `nomodeset` remains visible and reaches userspace, the machine is running
  and the failure is in the native display takeover.
- If only the one-CPU entry progresses, investigate PSCI/secondary CPU or idle
  handling with logs before changing the DT topology.
- If all entries become black, retrieve the persistent journal or initramfs log;
  black video alone cannot distinguish a boot hang from a backlight failure.
- If the premount entry exposes no USB disk and its LED never resumes activity,
  debug the `i2c18:0x4f` PTN3222 path before altering display or CPU topology.

## Validation boundary

The earlier display-only source was preprocessed and compiled with `dtc` on
Windows. Its local DTB was 213826 bytes with SHA-256
`3317e3073d483911d7f985591e2d1aa26908dc65ffee869520b97cfc56472057`.
A later USB-corrected DTB is recorded in `BUILD_RECORD.md`.
A full Linux kernel/config/schema build and a new physical test are still
required. The recovery GRUB file in this repository is a template; no USB or
internal storage was modified while preparing this revision.
