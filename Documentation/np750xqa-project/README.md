# NP750XQA Linux port project hand-off

This directory is the canonical hand-off for the experimental Linux port to
the Samsung Galaxy Book4 Edge NP750XQA with Snapdragon X Plus X1P42100.

If an AI agent is continuing this project, it must read every file in this
directory before changing code or preparing boot media. The user should not
need to repeat the project history.

## Repository state

- Fork: <https://github.com/RaikaShinohara/linux-book4-edge>
- Working branch: `codex/x1p42100-samsung-np750xqa`
- Upstream reference branch: `zensanp/x1e80100-book4e-6.17-rc4`
- Base commit: `708b2aeff3e9e014aaf6ec36e3de0e43b7c23aa5`
- Board DTS:
  `arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dts`
- Kernel configuration: `arch/arm64/configs/book4_defconfig`

## Read order

1. [HANDOFF.md](HANDOFF.md) -- objective, completed work and hard constraints.
2. [HARDWARE.md](HARDWARE.md) -- evidence captured from the physical machine.
3. [NEXT_STEPS.md](NEXT_STEPS.md) -- work expected from the next AI agent.
4. [TEST_PLAN.md](TEST_PLAN.md) -- recoverable first-boot and logging plan.
5. [../arch/arm64/samsung-galaxy-book4-edge-x1p42100.rst](../arch/arm64/samsung-galaxy-book4-edge-x1p42100.rst)
   -- user-facing kernel build notes.

## Current milestone

The repository contains a conservative first-boot DTB, not a proven hardware
port. It is intended to reach a recovery initramfs with USB, internal UFS and
the internal keyboard. Native internal display, touchpad and camera support are
deliberately deferred.

No firmware, partition, UFS content or Windows boot entry was modified while
creating this work.
