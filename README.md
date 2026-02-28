## About

Linux & DTS to allow booting on the X1E80100 Samsung Galaxy Book4 Edge, derived from [vamanea/linux-magicbook](https://github.com/vamanea/linux-magicbook), as these devices seem to share some similarities. Essentials working, but some things remain untested.

Thread: https://bugs.launchpad.net/ubuntu-concept/+bug/2084591

## Status
Supported features:
- [x] Keyboard - needs udev [quirk](https://bugs.launchpad.net/ubuntu-concept/+bug/2084591/comments/87)
   - [ ] Keyboard backlight
- [x] Touchpad
- [x] USB type-c
  - [ ] USB hotplug (limited, at least on the 14")
- [x] UFS storage - power management generates some kernel warnings but nothing fatal
- [x] HDMI port on the right side
- [x] Built-in display - fixed using the following (included) [patch](https://bugs.launchpad.net/ubuntu-concept/+bug/2084591/comments/99)
- [x] GPU - needs firmware + updated Mesa (tested on 25.3.3). [Enable](https://github.com/zensanp/linux-book4-edge/blob/49323f22adcc3d54c47c985622bdab90f1663aab/arch/arm64/boot/dts/qcom/x1e80100-samsung-galaxy-book4-edge.dts#L839) only after updating, or black screen after boot.
- [ ] Touchscreen
- [x] Wifi - needs firmware. 14" version also needs a patched board-2.bin as discussed [here](https://github.com/zensanp/linux-book4-edge/issues/3)
- [x] BT - needs firmware + MAC address must be set [manually](https://github.com/zensanp/linux-book4-edge/issues/5) for device.
- [x] ADSP and CDSP - need firmware
  - [ ] Battery indicator
- [ ] Audio - untested / needs firmware(?)
- [ ] DP Altmode - untested / needs firmware(?)
- [x] Sleep - Does it work? [Yes]. Does it save power? [Not really].
- [ ] Webcam - untested / needs firmware(?)
