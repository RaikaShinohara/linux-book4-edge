# Experimental KDB internal-display bring-up

This document records why the display implementation differs from both the
Qualcomm X1 CRD and the Samsung X1E reference. Nothing here is a claim of a
successful physical boot.

## Evidence from NP750XQA

- The captured EDID identifies KDB product `0x0526`, panel text
  `KD156N2030A03`, 1920x1080 at approximately 60 Hz.
- The same panel identifier is used as a standard eDP display in other Samsung
  x86 laptops; it is not an ATNA OLED panel.
- The ACPI `GPU0` panel profile requests dynamic EDID and DPCD reads over eDP,
  active-high HPD and zero milliseconds of panel power-up wait.
- That profile describes PMIC PWM backlight control at 19.2 kHz with 9-bit
  resolution. It does not identify a Linux PWM controller or a safe
  board-specific backlight-enable GPIO.
- ACPI display power resources explicitly vote the DP3 clocks and the
  `LDO2_J`/`LDO3_J` PHY rails, matching `vreg_l2j_1p2` and `vreg_l3j_0p8`.
- X1 reference designs consistently place the panel 3.3 V enable on TLMM GPIO
  70. This remains inherited from `x1-crd.dtsi`; it is the main unverified
  board-level assumption in this test.

## Implementation

- `mdss_dp3` and `mdss_dp3_phy` are enabled.
- The inherited `samsung,atna45af01` / `samsung,atna33xc20` node is replaced by
  the generic `edp-panel` compatible so EDID and DPCD determine panel details.
- The inherited ATNA PMIC GPIO 4 enable and its pinctrl state are deleted.
- `no-hpd` avoids blocking on a separate HPD GPIO that has not been confirmed
  for NP750XQA. AUX discovery and the ACPI-reported zero power-up delay are
  used for the first test.
- `CONFIG_DRM_MSM`, `CONFIG_DRM_PANEL_EDP` and `CONFIG_PHY_QCOM_EDP` are built
  in so the native framebuffer can appear before the external root mounts.
- The Adreno GPU is disabled for this milestone because its firmware is absent.
  MSM DPU scanout does not require 3D acceleration for a framebuffer console.
- The recovery GRUB template enables `drm.debug=0x1ff`, and the systemd logger
  no longer sleeps for 60 seconds before collecting evidence.

## Source validation on the Windows machine

The updated source was preprocessed and compiled with `dtc` 1.7.2, then
decompiled for a semantic round trip. Automated assertions confirmed that
DP3 is enabled, the panel is `edp-panel`, `power-supply` and `no-hpd` remain,
the inherited ATNA enable/pinctrl properties are absent, and the GPU is
disabled.

- DTB size: 213348 bytes
- DTB SHA-256:
  `CC445BB69E707EC737E39EE3898CFA1A58022DF06FB0BF59443E9D2F579478D8`

This validates the Device Tree structure only. The full kernel, resolved
Kconfig and DT schemas still have to be built on the Arch workstation, and no
physical display result has been claimed.

## Build the display kernel on Arch Linux

Use a native, case-sensitive Linux filesystem. Start from the published
display branch and do not reuse `Image`, modules or the DTB from the earlier
first-boot artifact:

```sh
git clone --branch codex/np750xqa-display \
    https://github.com/RaikaShinohara/linux-book4-edge.git
cd linux-book4-edge

make O=out ARCH=arm64 LLVM=1 book4_defconfig
grep -E 'CONFIG_(DRM_MSM|DRM_PANEL_EDP|PHY_QCOM_EDP)=' out/.config

make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" \
    Image modules qcom/x1p42100-samsung-galaxy-book4-edge.dtb
```

All three queried display options must resolve to `y`. Validate the board
schema and resolved DTB before installing anything:

```sh
make O=out ARCH=arm64 LLVM=1 \
    DT_SCHEMA_FILES=qcom.yaml dt_binding_check
make O=out ARCH=arm64 LLVM=1 CHECK_DTBS=y \
    DT_SCHEMA_FILES=qcom.yaml \
    qcom/x1p42100-samsung-galaxy-book4-edge.dtb

sha256sum out/arch/arm64/boot/Image \
    out/arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dtb \
    out/.config
```

The two boot artifacts are:

- `out/arch/arm64/boot/Image`
- `out/arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dtb`

Install the new `Image`, its modules and this DTB as one matched set on the
removable recovery system. Keep the previous working files as a fallback and
verify the external mount path before copying. Do not write to internal UFS or
change the permanent Windows EFI entry.

## Expected boot sequence

1. Samsung UEFI and GRUB should remain visible using the firmware framebuffer.
2. GRUB loads the new `Image`, recovery initramfs and matching NP750XQA DTB.
3. `simpledrm` can initially keep using the UEFI framebuffer while the built-in
   Qualcomm display stack probes.
4. MSM DRM enables DP3 and its PHY, powers the inherited 3.3 V panel rail and
   asks `panel-edp` to read the KDB EDID over AUX.
5. If AUX and link training succeed, MSM DRM exposes the preferred 1920x1080
   mode and `fbcon` replaces the firmware console with the native console.
6. The external root should mount read-only first, userspace should start and
   the logger should collect evidence without the previous 60-second delay.

The useful success criterion is readable console text, not a graphical
desktop. Adreno acceleration is deliberately disabled. Video may work at a
fixed firmware-selected brightness because the Samsung PMIC backlight control
is not yet described.

## Expected observations

The best result is a visible framebuffer console and a log showing:

1. `panel-edp` reading KDB product `0x0526` over AUX;
2. DP link training on `mdss_dp3`;
3. a connected eDP connector with the 1920x1080 preferred mode; and
4. `fbcon` attaching after MSM DRM replaces the firmware framebuffer.

Video with fixed brightness is a useful partial success. Do not add a PWM or
GPIO solely to make brightness adjustable until Linux logs or additional
firmware evidence identify the Samsung backlight path.

If AUX cannot read EDID, first inspect the 3.3 V rail, PHY regulator votes and
DP3 probe ordering. If link training fails after EDID succeeds, test a maximum
link frequency of 5.4 GHz before changing lane routing or power GPIOs.
