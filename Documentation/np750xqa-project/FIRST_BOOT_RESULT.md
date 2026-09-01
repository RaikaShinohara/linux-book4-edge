# First physical boot result

## Test summary

The first physical recovery-USB test was performed with Secure Boot disabled,
using the laptop's USB-A port and the removable-media UEFI entry. GRUB was
visible and the experimental Linux entry was selected. After control passed to
Linux, the internal panel went black. The machine did not visibly return to
firmware or Windows and required a prolonged power-off action.

This is consistent with the documented display limitation and is not, by
itself, proof of a kernel hang. Native internal eDP remains disabled in the
NP750XQA DTB because the factory KDB `KD156N2030A03` panel is not described by
the inherited Qualcomm CRD panel data.

## Offline USB inspection

After the test, the removable root filesystem was reconnected to the Arch
workstation and inspected. The desktop initially auto-mounted it read-write;
it was immediately remounted read-only for the investigation.

Observed state:

- the ext4 filesystem was clean;
- the kernel, matching DTB, initramfs and first-boot logger were intact;
- the ext4 mount counter was compatible with an additional mount during the
  laptop test, but this is circumstantial rather than conclusive evidence;
- `/var/log/np750xqa/` had not been created;
- no persistent systemd journal was present.

The logger was configured to sleep for 60 seconds after reaching
`multi-user.target`. Therefore the absence of its output only proves that this
condition was not satisfied long enough; it does not identify whether the
kernel, initramfs or userspace was the stopping point.

## Display state

The kernel configuration already contains the text-console prerequisites:

- `CONFIG_VT=y` and `CONFIG_VT_CONSOLE=y`;
- `CONFIG_FRAMEBUFFER_CONSOLE=y`;
- `CONFIG_SYSFB=y`, `CONFIG_SYSFB_SIMPLEFB=y` and
  `CONFIG_DRM_SIMPLEDRM=y`;
- the command line requests `console=tty0 loglevel=8 ignore_loglevel`.

These settings can use a firmware-provided framebuffer, but the first test
showed that no usable framebuffer remained after the kernel transition. They
do not replace a native eDP description.

## Required next milestone

Before another blind test, improve diagnostics so that evidence is written as
soon as the external root becomes writable, rather than 60 seconds after
`multi-user.target`. Persistent journald storage and an initramfs-stage capture
should be considered. Do not infer success solely from the ext4 mount count.

In parallel, investigate native display support for the exact KDB panel. The
work must establish the NP750XQA-specific eDP endpoint, AUX path, regulators,
backlight, enable/reset GPIOs and power sequencing from hardware evidence.
Do not simply enable `mdss_dp3` with the incompatible ATNA CRD panel.
