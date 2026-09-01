# Expected next steps after the first physical boot

> Historical note: phases 1 through 6 below were completed on the Arch
> workstation. Build and USB details are in `BUILD_RECORD.md` and
> `USB_RECOVERY_RECORD.md`. The first physical result is recorded in
> `FIRST_BOOT_RESULT.md`.

The next AI agent should execute these phases in order. It should stop before
physical boot preparation if the kernel and DT schema do not validate cleanly.

## 1. Establish a clean Linux workspace

Clone the published branch onto a native, case-sensitive Linux filesystem::

    git clone --branch codex/x1p42100-samsung-np750xqa \
        https://github.com/RaikaShinohara/linux-book4-edge.git
    cd linux-book4-edge
    git status --short --branch

The new clone should not contain the case-collision modifications seen on the
original FAT32 drive.

Record the starting commit and do not rewrite the published branch history.
Create a new topic branch for fixes found during compilation.

## 2. Validate schemas and configuration

Install the normal Arch kernel build dependencies and a current `dtschema`
toolchain. Verify current package names from official Arch sources before
installing them.

At minimum, run::

    make O=out ARCH=arm64 LLVM=1 book4_defconfig
    make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" \
        qcom/x1p42100-samsung-galaxy-book4-edge.dtb
    make O=out ARCH=arm64 LLVM=1 CHECK_DTBS=y \
        qcom/x1p42100-samsung-galaxy-book4-edge.dtb

Also run the Qualcomm board binding check with the repository's supported
`dt_binding_check` invocation. Fix new-board errors, but do not mix unrelated
warnings inherited from the base branch into this port unless necessary.

Confirm in `out/.config` that the UFS host, Qualcomm UFS glue, QMP core and QMP
UFS PHY remain built in. Compare the resulting DTB model, compatible strings
and critical statuses with the assertions listed in `HANDOFF.md`.

## 3. Build the complete kernel

Build with the same configuration and toolchain::

    make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" Image modules

Do not silently disable a driver to get a successful build. Document every
configuration or source change in a new commit. Record hashes for the final
`Image`, DTB, `.config` and module tree.

## 4. Inventory required firmware

Before constructing an initramfs:

- Enumerate every `firmware-name` used by the resolved NP750XQA DTB.
- Check current `linux-firmware` first.
- Compare missing files against the user's own Windows installation and the
  two reference projects.
- Do not use X1E firmware merely because the filename looks plausible.
- Record source, hardware identifier and SHA-256 for every copied firmware
  file. Do not commit proprietary firmware to this repository.

GPU, FastConnect, ADSP and CDSP are expected to require firmware. They are not
required to prove the earliest UFS/USB/initramfs milestone, so defer them if
they complicate the first recovery image.

## 5. Prepare an Arch-based ARM64 recovery root

Select a currently maintained AArch64 root filesystem compatible with Arch or
an Arch-based distribution. Verify its present support and installation method
from official sources; do not assume an x86-64 Arch installation image can boot
on this ARM64 laptop.

The first image should be a minimal recovery environment, not a desktop. It
needs:

- the exact kernel modules built above;
- the DTB and kernel `Image` from the same commit;
- an initramfs shell;
- USB host, USB storage/UAS, SCSI and the chosen external-root filesystem;
- logging tools and enough networking only if it can be configured safely;
- a mechanism to save `dmesg` and probe information to removable media.

Internal UFS should not be selected as the root filesystem for the first boot.

## 6. Determine the boot packaging from evidence

Investigate how the reference X1E project passes a DTB to the Samsung UEFI.
Possible mechanisms include a bootloader `devicetree` command, an appended DTB
or a purpose-built EFI image, but the next agent must confirm the mechanism
before producing commands.

Do not assume that systemd-stub will load an arbitrary external DTB. Do not
change the default Windows boot entry. Prefer a removable EFI System Partition
and a one-time firmware boot selection. If Secure Boot affects the chosen
loader, present signed and user-authorized options rather than changing it
silently.

## 7. Prepare, but do not improvise, the first physical test

Follow `TEST_PLAN.md`. The initial goal is only:

1. UEFI loads the experimental bootloader from removable media.
2. The kernel starts with the correct DTB.
3. The recovery initramfs runs.
4. USB and the external root/log device enumerate.
5. Internal UFS probes without being mounted read-write.
6. The internal keyboard probes.
7. Logs are saved for offline inspection.

Only after those stages are repeatable should the project add touchpad,
internal display, audio, EC, suspend or a desktop Arch environment.

## 8. Current priority: early evidence and internal display

The first attempt reached GRUB, then lost the internal image. No delayed
first-boot log was produced. For the next attempt:

1. Capture and sync `dmesg` during initramfs or immediately after mounting the
   external root; do not wait for `multi-user.target`.
2. Make the systemd journal persistent on the removable root.
3. Preserve the verbose `tty0` command line, while recognizing that it only
   works if firmware simpledrm remains usable.
4. Determine the exact NP750XQA eDP AUX, endpoint, backlight, regulator, GPIO
   and sequencing data for the KDB `KD156N2030A03` panel.
5. Enable `mdss_dp3` only when those facts are supported by NP750XQA evidence.

The inherited CRD uses a different ATNA panel. Enabling it unchanged is not a
valid display implementation and may apply an incorrect power sequence.
