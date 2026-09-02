# NP750XQA Linux port project hand-off

This directory is the canonical hand-off for the experimental Linux port to
the Samsung Galaxy Book4 Edge NP750XQA with Snapdragon X Plus X1P42100.

If an AI agent is continuing this project, it must read every file in this
directory before changing code or preparing boot media. The user should not
need to repeat the project history.

## Repository state

- Fork: <https://github.com/RaikaShinohara/linux-book4-edge>
- Working branch: `codex/np750xqa-display`
- Display branch base: `codex/np750xqa-build-fixes` at
  `ddace7b585832aa5e65b044e3c342fcedba3c88f`
- Display implementation commit:
  `8a3a9d850a41ee2def109a4334b4b62b1909b3e5`
- Built-in display dependency commit tested in the second physical attempt:
  `ba45a7e703197cbf15d6a8b1ecafebd9f27306cd`
- Revised DP3 HPD and PMK8550 backlight commit awaiting a Linux build/test:
  `65fe4cdbf3a52b6f01e5b806232fab8fe03619c7`
- USB-A topology and built-in root-driver correction:
  `25c1771b1` (`arm64: qcom: fix NP750XQA USB-A root path`)
- Upstream reference branch: `zensanp/x1e80100-book4e-6.17-rc4`
- Base commit: `708b2aeff3e9e014aaf6ec36e3de0e43b7c23aa5`
- Board DTS:
  `arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dts`
- Kernel configuration: `arch/arm64/configs/book4_defconfig`

## Read order

1. [HANDOFF.md](HANDOFF.md) -- objective, completed work and hard constraints.
2. [HARDWARE.md](HARDWARE.md) -- evidence captured from the physical machine.
3. [NEXT_STEPS.md](NEXT_STEPS.md) -- work expected from the next AI agent.
4. [DISPLAY_BRINGUP.md](DISPLAY_BRINGUP.md) -- display evidence and current
   implementation assumptions.
5. [SECOND_BOOT_RESULT.md](SECOND_BOOT_RESULT.md) -- latest physical result,
   revised HPD/backlight implementation and CPU/hypervisor diagnostics.
6. [USB_BRINGUP.md](USB_BRINGUP.md) -- USB-A failure evidence, corrected
   repeater topology, built-in driver chain and premount diagnostic procedure.
7. [TEST_PLAN.md](TEST_PLAN.md) -- recoverable first-boot and logging plan.
8. [../arch/arm64/samsung-galaxy-book4-edge-x1p42100.rst](../arch/arm64/samsung-galaxy-book4-edge-x1p42100.rst)
   -- user-facing kernel build notes.

The latest workstation build and validation results are recorded in
[BUILD_RECORD.md](BUILD_RECORD.md).

The prepared removable recovery system is described in
[USB_RECOVERY_RECORD.md](USB_RECOVERY_RECORD.md), and the physical procedure is
in [FIRST_BOOT.md](FIRST_BOOT.md).

## Current milestone

The repository contains a conservative first-boot DTB, not a proven hardware
port. It is intended to reach a recovery initramfs with USB, internal UFS and
the internal keyboard. The native KDB display path is now enabled
experimentally; touchpad and camera support remain deliberately deferred.

The first physical attempt is documented in `FIRST_BOOT_RESULT.md`. The second
attempt used a matched kernel/DTB with the native display stack built in, showed
some Linux output and then went black; see `SECOND_BOOT_RESULT.md`. No kernel
log was recovered, so the current boot depth remains unproven. The next build
must first test whether Linux reacquires the USB-A root using the corrected
`i2c18:0x4f` PTN3222 path. The default GRUB diagnostic stops before mounting
root and logs early userspace. Once USB is proven, test real DP3 HPD plus the
PMK8550 PWM backlight and use the remaining entries to separate native-display
takeover from CPU/boot progression.

No firmware, partition, UFS content or Windows boot entry was modified while
creating this work.
