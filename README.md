## About

Linux & DTS to allow booting on the X1E80100 Samsung Galaxy Book4 Edge, derived from https://github.com/vamanea/linux-magicbook, as these devices seem to share some similarities. Some basic features appear to be working, but some things that require firmware are still untested.

Thread: https://bugs.launchpad.net/ubuntu-concept/+bug/2084591

This branch also contains an initial Device Tree for the 15.6-inch Samsung
Galaxy Book4 Edge NP750XQA with the Snapdragon X Plus X1P42100. See the
[NP750XQA bring-up notes](Documentation/arch/arm64/samsung-galaxy-book4-edge-x1p42100.rst)
and the [board Device Tree](arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dts).

## X1P42100 NP750XQA status

**Nothing in this section has been confirmed by a Linux boot on the physical
machine yet.** The entries below describe what is expected from the current
Device Tree and kernel configuration, not tested hardware support.

### Expected to work in the initial bring-up

- **CPU and memory:** the X1P42100 SoC description, interrupt controller,
  timers, clocks, power domains, eight CPU cores and 16 GiB memory layout come
  from the existing Qualcomm X1P42100/Purwa support.
- **Internal UFS:** the host controller, PHY and regulator assignments are
  enabled. The UFS host, Qualcomm glue and QMP UFS PHY are built into
  `book4_defconfig`, so storage should be available before loading modules. A
  board-specific reset line may still be required if the first probe fails.
- **Internal keyboard:** the Samsung HID-over-I2C keyboard is described at
  address `0x05`, with HID descriptor `0x20` and the interrupt mapping matching
  the Samsung firmware resources.
- **Basic USB:** the USB controllers inherited from the X1P42100 CRD are
  enabled and should provide a recovery input/storage path. The exact Samsung
  Type-C retimer and connector routing is not confirmed yet.
- **PCIe and Wi-Fi enumeration:** the relevant PCIe controllers are enabled.
  FastConnect 7800 should be usable after confirming the correct PCIe path and
  installing the matching Qualcomm firmware and board data.
- **GPU probe:** the Adreno GPU node is enabled and should probe with the
  correct firmware. This does not imply that the internal display works;
  recent Mesa and the matching GPU firmware will also be required.
- **ADSP and CDSP:** both remote processors are enabled in the inherited base
  and should start when the matching firmware is installed.
- **Firmware framebuffer:** it may keep the internal panel visible during early
  boot, before the Linux display driver takes ownership. This is firmware
  dependent and is not a replacement for native panel support.

### Deliberately disabled or still pending

- **Internal display:** native eDP is disabled because the NP750XQA uses a KDB
  `KD156N2030A03` panel rather than the ATNA panel described by the CRD.
- **Touchpad:** the Zinitix device is known to be at `0x40` on `i2c13`, but its
  HID descriptor address comes from a runtime ACPI NVS value and has not been
  guessed.
- **Camera:** CAMSS is disabled because the CRD camera sensor is not a valid
  description of this Samsung board.
- **Touchscreen and fingerprint reader:** no board-specific nodes have been
  added.
- **Audio:** codec, amplifiers, microphones and Samsung-specific routing have
  not been described or tested.
- **Samsung EC and battery features:** battery reporting, charging limits,
  keyboard backlight, platform profiles and EC notifications are not integrated
  yet.
- **Bluetooth:** it will require the correct firmware and board-specific setup;
  it is not currently claimed as working.
- **External display and DP Alt Mode:** controller availability does not confirm
  Type-C mux, retimer or display output support.
- **Suspend, hibernate, thermal and fan behaviour:** all require physical testing
  before they can be considered safe or functional.

### First test criteria

The first boot should be considered successful if the kernel reaches a recovery
initramfs, exposes a console, enumerates USB and probes the UFS controller
without fatal errors. Keep the Windows EFI entry and recovery media intact, and
do not write to internal UFS during this first test. Capture the complete early
console and `dmesg` log for the next Device Tree revision.

## X1E80100 status
Supported features:
- [x] Keyboard - needs udev [quirk](https://bugs.launchpad.net/ubuntu-concept/+bug/2084591/comments/87)
- [x] Touchpad - note: use dts from [this branch](https://github.com/zensanp/linux-book4-edge/blob/x1e80100-book4e-14-temp-6.17-rc4/arch/arm64/boot/dts/qcom/x1e80100-samsung-galaxy-book4-edge.dts) if on the 14" version
- [x] USB type-c
- [x] UFS storage - power management generates some kernel warnings but nothing fatal
- [x] HDMI port on the right side
- [x] Built-in display - fixed using the following [patch](https://bugs.launchpad.net/ubuntu-concept/+bug/2084591/comments/99)
- [x] GPU - needs firmware + updated Mesa (tested on 25.3.3). [Enable](https://github.com/zensanp/linux-book4-edge/blob/49323f22adcc3d54c47c985622bdab90f1663aab/arch/arm64/boot/dts/qcom/x1e80100-samsung-galaxy-book4-edge.dts#L839) only after updating, or black screen after boot.
- [ ] Touchscreen
- [x] Wifi - needs firmware. 14" version also needs a patched board-2.bin as discussed [here](https://github.com/zensanp/linux-book4-edge/issues/3)
- [x] BT - needs firmware + MAC address must be set [manually](https://github.com/zensanp/linux-book4-edge/issues/5) for device. 

- [x] ADSP and CDSP - need firmware 
- [ ] Audio - untested / needs firmware(?)
- [ ] DP Altmode - untested / needs firmware(?)
- [x] Sleep - Does it work?: Yes. Does it save power?: Not really. 
- [ ] Hibernate - untested
