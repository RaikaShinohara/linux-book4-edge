# USB test 3: NP750XQA, 2026-09-07

Branch: `codex/np750xqa-usb-test-3`, based on USB test 2 at `7475666df`.
This is the current continuation guide. Earlier build/media hashes describe
older artifacts, not this branch. No new kernel or USB medium was built here.

## What actually booted

The recorded early-shell test reached Linux `/init` and accepted keyboard
input. That is Linux kernel plus initramfs userspace, already beyond kernel
initialization. It is not evidence that the external Arch root mounted or that
systemd started. An intentional early/premount shell waits for `exit`.

Success for this milestone means a mounted external root, systemd services,
and eventually a text login. A desktop is not the current target. A black
panel cannot distinguish a display hand-off failure from stalled storage.
The self-contained GRUB embeds the kernel, DTB and initramfs: loading those
does NOT demonstrate that Linux can read the stick with its own USB drivers.

## Evidence and remaining uncertainty

- Read-only inspection on this laptop confirms Samsung Galaxy Book4 Edge,
  X1P42100 (8 cores). Windows PnP history for the Kingston DT 101 II gives
  `ACPI(_SB_)#ACPI(USB3)#ACPI(RHUB)#ACPI(MP1_)`. This is a disconnected-device
  history record, not a fresh Linux enumeration. No USB disk is currently
  attached; the visible disks are internal UFS and the SD card hosting E:.
- The saved local factory DSDT (`E:\Linux\hardware\acpi\dsdt-SDM8380-rev3.dsl`)
  describes USB3 at 0x0a400000, MP1 as connectable, and resources IC19
  (0x00888000), addresses 0x43/0x4f and GPIO6/7. The second address/reset pair
  mapping to MP1 remains an inference. No fresh I2C probe or GPIO toggling was
  attempted from Windows. Do not publish device serials or raw hardware dumps.
- USB test 2 recovery DT forced MP0/i2c5/GPIO184 copied from the X Elite
  14-inch board. This conflicts with this machine's recorded port and is
  removed. Recovery now inherits the NP750XQA board USB definition including
  MP1/i2c18:0x4f/GPIO7, without changing normal-board USB or inventing another
  reset line. Other inherited PHYs remain; this is not a single-port isolation.
- `vph_pwr` is a `regulator-fixed` feeding upstream PMIC supplies. The old
  `CONFIG_REGULATOR_FIXED_VOLTAGE=m` contradicted the claimed fully built-in
  path. It is now `y`, included in the checker (22 symbols), and `fixed` is
  explicitly listed in mkinitcpio as a fallback for modular configurations.
  This does NOT prove the old initramfs lacked it: mkinitcpio's block installer
  also includes regulator modules. Inspect the actual archived initramfs.
- `qcom-rpmh-regulator.c` unwinds a provider group when registration fails.
  `regulator/core.c` can defer always-on rails while their supplies are absent.
  The inherited PM8550VE-j SMPS5 supply is `vph_pwr`, not a direct BOB1 link;
  the previously asserted B/J cycle is not proven. `fw_devlink=off` cannot
  make missing physical supplies appear. Compare it with `fw_devlink=on` using
  the new otherwise identical menu entry, rather than declaring a cycle fixed.
- DWC3 initializes its listed PHYs; a failing SuperSpeed supply can block the
  controller even with a USB2 stick. Removing a PHY reference is not proof of
  correct operation. Do not remove regulator/repeater dependencies just to
  silence a deferred probe.
- No logs and unchanged ext4 timestamps do not prove non-enumeration; a
  read-only mount may leave no persistent timestamp. USB LED activity alone
  does not identify retries. The historical record now makes this explicit.
- Nothing identifies the hypervisor or secondary CPUs as the failure cause.
  Reaching `/init` disproves a total pre-userspace boot failure, but does not
  certify every core. Leave EL2/PSCI and firmware settings unchanged.

## Diagnostic changes

The log hook writes RAM snapshots in `/run/initramfs/np750xqa/` at
`early-initramfs`, `before-root-resolution`, `after-root-mount-attempt` and
`emergency`. It prints stage markers, mounts debugfs for `devices_deferred`,
and reads USB attributes through sysfs device entries instead of an ineffective
non-following `find`. The after-mount marker alone does NOT prove a root mount;
inspect its `mounts.txt` for `/sysroot` and the expected external device.

After the early stage, snapshots can be copied to
`NP750_EFI:/np750xqa-early-logs/<boot-id>/`, selecting UUID `2A8E-8A5D` and
requiring a USB ancestor. A non-USB disk is refused. For replacement media set
`np750.loguuid=<actual-ESP-UUID>` and update `root=UUID=` in GRUB. There is no
fallback to Windows' ESP. If USB is absent, snapshots remain in RAM and are
lost on power-off: photograph the console or retrieve them from a working
shell before rebooting. This cannot create persistent logs without storage.

Mount/copy/unmount have timeouts, but kernel I/O stuck in uninterruptible sleep
cannot be guaranteed to stop on a userspace timeout. An unmount failure means
the FAT copy is not confirmed durable. No background writer races with the
root hand-off. Later hooks retry persistence; there is no periodic USB write.

The real-root service copies the RAM snapshots and writes `stage.txt` under
`/var/log/np750xqa/<timestamp>/`. It no longer waits for global udev settle.
Its marker proves real-root userspace, not that every service reached its target.
The udev hook now checks daemon startup and creates the tmpfiles directory.

The GRUB root-device polling budget is 90 seconds per mkinitcpio resolution
instead of 5. This is not a 90-second total boot deadline, and `rootwait` does
not impose an infinite wait on mkinitcpio. Default boot is automatic; use the
explicit premount-shell entry only when prepared to type `exit`.

## Next AI on the Arch i9 workstation

1. Fetch and check out this branch on a native case-sensitive Linux filesystem.
   Preserve old media artifacts and record the exact Git SHA. Do not write to
   the laptop's internal UFS, change firmware, or repartition any device.
2. Compile the matched Image, modules and BOTH DTBs. With the project's LLVM
   build prerequisites installed, from repository root:

   ```sh
   make O=out-usb3 ARCH=arm64 LLVM=1 book4_defconfig
   make O=out-usb3 ARCH=arm64 LLVM=1 -j"$(nproc)" Image modules \
     qcom/x1p42100-samsung-galaxy-book4-edge.dtb \
     qcom/x1p42100-samsung-galaxy-book4-edge-recovery.dtb
   sh Documentation/np750xqa-project/recovery/check-usb-root-config.sh out-usb3/.config
   sh Documentation/np750xqa-project/recovery/test-log-hook.sh
   make O=out-usb3 ARCH=arm64 LLVM=1 kernelrelease
   ```

   Run the existing DT schema validation procedure too. Treat warnings as
   findings to assess, not evidence of a tested port. Inspect the resolved DTB:
   MP1 enabled and referencing the i2c18 repeater, old i2c5 repeater disabled,
   and DP3/backlight/PWM disabled only in recovery.
3. Positively identify the external USB by transport, capacity and UUIDs before
   any installation. Install modules for the exact new kernel release into
   the external AArch64 root, run depmod for that release and rebuild mkinitcpio
   inside that AArch64 root (using the existing QEMU workflow on x86). Do NOT
   use the i9 host's x86 binaries or its currently running kernel release.
4. Copy the two `initcpio-install-*` files for np750udev and np750log to
   `/etc/initcpio/install/{np750udev,np750log}`, and the matching runtime hooks
   to `/etc/initcpio/hooks/{np750udev,np750log}`, all mode 0755. Use the updated
   `mkinitcpio-np750xqa.conf`. Inside the AArch64 root run
   `mkinitcpio -k <exact-new-release> -c <copied-config> -g <new-initramfs.img>`.
   Check success and use `lsinitcpio`/extraction to inspect `/config`, executable
   hooks, `timeout`, `findfs`, FAT support and modules matching the new release.
   Run hook syntax and mock tests with the actual BusyBox ash as well.
5. Update `/usr/local/sbin/np750-firstboot-log` (0755) and its systemd unit on
   that external root. Ensure it is enabled for multi-user.target. Keep the
   internal disks absent from fstab; preserve the existing external-only setup.
6. Rebuild the self-contained EFI loader. Merely replacing Image/DTB/initramfs
   files on the FAT partition does NOT update copies embedded in BOOTAA64.EFI.
   In a staging directory place `Image`, `board.dtb`, `recovery.dtb`,
   `initramfs.img` and this branch's `grub.cfg`. With GRUB arm64-efi modules
   available (the existing AArch64 build environment supplies them):

   ```sh
   grub-mkstandalone -O arm64-efi -o BOOTAA64-usb3.EFI \
     --modules='normal linux memdisk tar' \
     'boot/grub/grub.cfg=grub.cfg' \
     'np750xqa/Image=Image' 'np750xqa/board.dtb=board.dtb' \
     'np750xqa/recovery.dtb=recovery.dtb' \
     'np750xqa/initramfs.img=initramfs.img'
   sha256sum Image board.dtb recovery.dtb initramfs.img grub.cfg BOOTAA64-usb3.EFI
   ```

   Validate the menu with `grub-script-check`, inspect the embedded artifact
   mapping, and record hashes before installing this loader to the identified
   removable fallback path `EFI/BOOT/BOOTAA64.EFI`. Keep the old loader as a
   named backup. Do not use grub-install against internal storage/NVRAM.
7. Boot the default test 3 entry first. Record the menu label and video for
   several minutes, not only initial output. Look for stage markers, xHCI,
   Kingston enumeration, SCSI disk, `/sysroot` mount and systemd/login. Retrieve
   FAT logs and real-root logs independently. If no progress, use the premount
   shell and photograph `dmesg`, `devices_deferred`, `/proc/mounts` and UUIDs.
8. Compare the `fw_devlink=on` entry with the same compiled artifacts and stick.
   A visible shell permits `cat /sys/devices/system/cpu/online` to check cores.
   Investigate the FIRST unmet supplier, not only downstream USB deferrals.
   Test native eDP separately after root progress is established. Do not equate
   firmware framebuffer visibility with a functional native panel driver.

## Validation in this Windows session

- 22 requested built-in symbols passed on `book4_defconfig` (not a newly
  resolved `.config`). Fixed-regulator Kconfig has no extra dependency beyond
  the enabled regulator framework.
- Log-hook mock cases passed under Git Bash and dash: RAM-only early capture,
  absent ESP, actual USB attribute output, refusal of an internal disk,
  failed FAT mount, and successful simulated USB copy/unmount.
- These are userspace mocks, not real mkinitcpio, FAT, USB, or hardware tests.
- WSL Debian cannot start: its registered `D:\WSL\Debian\ext4.vhdx` is missing.
  No repair of that unrelated installation was attempted. Kernel compilation,
  resolved Kconfig, DT build/schema and real initramfs assembly remain pending
  on Arch. No new boot was attempted or medium modified in this session.

## Sources checked

Local kernel sources: `arch/arm64/boot/dts/qcom/x1-crd.dtsi`, NP750XQA normal
and recovery DTS, `drivers/regulator/{core,qcom-rpmh-regulator}.c`,
`drivers/usb/dwc3/core.c`, and the existing hardware/boot records in this folder.

- [mkinitcpio init](https://raw.githubusercontent.com/archlinux/mkinitcpio/master/init): hook stages and real-root hand-off.
- [mkinitcpio init_functions](https://raw.githubusercontent.com/archlinux/mkinitcpio/master/init_functions): device polling and console shells.
- [mkinitcpio block installer](https://raw.githubusercontent.com/archlinux/mkinitcpio/master/install/block): regulator-module inclusion.
- [mkinitcpio build functions](https://raw.githubusercontent.com/archlinux/mkinitcpio/master/functions): executable runtime-hook discovery.
- [GRUB standalone manual](https://man.archlinux.org/man/grub-mkstandalone.1.en): memdisk graft-point packaging.

The mkinitcpio master links are moving references, consulted on 2026-09-07.
Confirm the installed Arch Linux ARM package has the same hook/poll semantics
and record its version when assembling the new image.
