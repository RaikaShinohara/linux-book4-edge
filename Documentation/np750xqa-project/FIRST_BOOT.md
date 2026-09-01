# First physical boot checklist

1. Keep Windows recovery media available and connect AC power.
2. Disable Secure Boot temporarily. Do not delete or replace its enrolled
   keys.
3. Insert the prepared `NP750_EFI` / `NP750_ROOT` USB drive into the laptop's
   USB-A port.
4. Use Samsung's one-time firmware boot menu and select the removable USB. Do
   not create a permanent boot entry.
5. In GRUB, select `NP750XQA recovery Linux (read-only first mount)`.
6. The internal display is experimental. The new kernel should hand the console
   from simpledrm to MSM DRM after reading the KDB EDID. A black screen is still
   not proof of a kernel hang; do not repeatedly reboot.
7. Allow several minutes for the first boot and log capture. Stop immediately
   for abnormal heat, fan, smell, charging behaviour, repeated resets or an
   apparent UFS power-cycle loop.
8. Perform a deliberate power-off after the agreed test window, return the USB
   to the Arch workstation and inspect `/var/log/np750xqa/` on `NP750_ROOT`.

Networking and SSH are deliberately disabled. Internal UFS must not be mounted
manually during this first test. Preserve the unfiltered logs before making a
redacted copy for publication.
