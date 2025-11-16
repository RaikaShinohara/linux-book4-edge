# Linux for Samsung Galaxy Book4 Edge with Snapdragon Elite (X1E80100)

## About

Linux & DTS to allow booting on the X1E80100 Samsung Galaxy Book 4 Edge, derived from https://github.com/vamanea/linux-magicbook, as these devices seem to share some similarities. Some basic features appear to be working, but most things that require firmware are untested.

## Status    
Supported features:
- [x] Keyboard 
- [x] Touchpad
- [x] USB type-c
- [x] UFS storage - power management generates some kernel warnings but nothing fatal
- [x] HDMI port on the right sid
- [ ] Display - Black screen when attempting to load drm/msm, but works on fallback with no modules
- [ ] Touchscreen
- [ ] PCIe ports (pcie4)
  - [ ] Wifi - untested / needs firmware(?)
  - [ ] BT - untested / needs firmware(?)

- [ ] ADSP and CDSP - untested / needs firmware(?)
- [ ] Audio - untested / needs firmware(?)
- [ ] DP Altmode - untested
- [ ] Sleep - untested
- [ ] Hibernate - untested
 
