# Non-destructive first-boot test plan

This is a plan for the next workstation and physical-device session. Creating
the documentation does not authorize the current agent to boot the machine or
modify storage.

## Build record

Before writing removable media, record:

- Git remote, branch and exact commit.
- `clang`, `ld.lld`, `make`, `dtc` and `dtschema` versions.
- SHA-256 of `Image`, DTB, initramfs and bootloader EFI binary.
- SHA-256 of `out/.config` and the installed module tree manifest.
- Firmware filenames, sources and SHA-256 values.
- The complete build command and all warnings.

Keep this record on the workstation and on the removable log partition.

## Recovery-media requirements

- Use removable media with its own EFI System Partition and external Linux
  root or recovery filesystem.
- Do not reuse a disk whose target identity is ambiguous.
- Give the external root and log filesystems unique labels or UUIDs.
- Configure the kernel command line to select the external root explicitly,
  mount it read-only initially and wait for USB enumeration.
- Include an emergency shell if the external root cannot be mounted.
- Do not include commands that repartition, format or automatically repair
  internal UFS.

Native internal display is experimental, so the recovery image must not rely
on it as the only evidence path. Prefer early console plus EFI pstore and an
initramfs log copied to removable media. Add `drm.debug=0x1ff` for the first
display test and use network logging only after the interface is known safe.

## Pre-boot checks

- Windows recovery media exists and the Windows EFI entry is unchanged.
- The experimental loader is selected only through the one-time firmware boot
  menu.
- AC power and battery state are stable.
- The removable target and its hashes match the build record.
- No internal UFS partition is configured for write access.
- A time limit and an immediate power-off criterion are agreed before boot.

## Success ladder

Record the highest completed stage rather than reporting only "booted" or
"failed":

1. Firmware starts the removable EFI loader.
2. Loader accepts the kernel, initramfs and NP750XQA DTB.
3. Kernel prints its version and the model
   `Samsung Galaxy Book4 Edge (NP750XQA)`.
4. Initramfs starts and exposes a shell or automatic logger.
5. USB host and removable storage enumerate.
6. UFS host `0x01d84000` and its PHY probe without a fatal timeout.
7. Kioxia UFS media appears but remains unmounted or read-only.
8. I2C0 and the Samsung keyboard at address `0x05` probe.
9. PCIe controllers enumerate; FastConnect probing may be deferred.
10. ADSP, CDSP and GPU errors are captured but are not first-boot blockers.

## Data to collect

Save unfiltered output first, then make summaries. Collect:

- complete loader output, early console and `dmesg`;
- `/proc/cmdline`;
- `/proc/iomem` and `/proc/interrupts`;
- `/sys/firmware/devicetree/base/model` and compatible strings;
- `lsblk`, `blkid` and UFS sysfs information without mounting internal media;
- I2C controller and HID probe messages;
- PCIe, USB, remoteproc, firmware-loader, DRM and thermal messages;
- pstore records after a crash or reboot;
- temperatures and fan observations made without sending EC commands.

Redact serial numbers, MAC addresses, filesystem UUIDs and other unique values
before publishing logs.

## Stop conditions

Power down and do not retry automatically if any of these occur:

- abnormal heat, fan behaviour, smell, battery behaviour or charging state;
- repeated UFS reset or power-cycling loops;
- firmware or bootloader attempts to write internal storage unexpectedly;
- the selected boot target is ambiguous;
- a watchdog causes uncontrolled repeated rebooting.

## After the first log

The next AI should classify failures in this order:

1. Boot packaging or DTB hand-off.
2. Kernel configuration and missing built-in storage/USB drivers.
3. UFS power, PHY and reset sequence.
4. External-root and initramfs timing.
5. Keyboard I2C and interrupt mapping.
6. PCIe and firmware-dependent subsystems.

Change one hardware assumption at a time and keep every test reproducible.
