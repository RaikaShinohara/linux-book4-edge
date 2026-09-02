# Reproducible build record

> This is the historical build used for the first physical attempt. It does
> not contain the later experimental display implementation. Build
> `codex/np750xqa-display` using
> [DISPLAY_BRINGUP.md](DISPLAY_BRINGUP.md) and replace its `Image`, modules and
> DTB together for the next test.

Build completed on 2026-08-31 on the Arch Linux x86-64 workstation.

## Source and toolchain

- Source commit: `1834be5b401f7f00901c9a5bb43272e24540834b`
- Build-fix branch: `codex/np750xqa-build-fixes`
- Clang: 22.1.8
- LLD: 22.1.8
- GNU Make: 4.4.1
- Kernel-bundled DTC: 1.7.2
- Schema validator: dtschema 2026.6
- Binary libfdt/DTC package used locally for schema validation: Arch Linux
  `dtc` 1:1.8.1-1, extracted below `out/` without installing it globally

The complete build commands were:

```text
make O=out ARCH=arm64 LLVM=1 book4_defconfig
make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" \
    qcom/x1p42100-samsung-galaxy-book4-edge.dtb
make O=out ARCH=arm64 LLVM=1 -j"$(nproc)" Image modules
```

The first complete build exposed three const-correctness errors in the bundled
libbpf when compiled with Clang 22. The build-fix branch changes only the three
affected local pointer declarations to `const char *`. No driver or
configuration option was disabled.

## Validation

The following targeted checks completed successfully with dtschema 2026.6,
yamllint 1.38.0 and the locally extracted Arch libfdt Python bindings:

```text
make O=out ARCH=arm64 LLVM=1 DT_SCHEMA_FILES=qcom.yaml dt_binding_check
make O=out ARCH=arm64 LLVM=1 CHECK_DTBS=y DT_SCHEMA_FILES=qcom.yaml \
    qcom/x1p42100-samsung-galaxy-book4-edge.dtb
```

The final configuration keeps these options built in:

```text
CONFIG_SCSI_UFSHCD=y
CONFIG_SCSI_UFSHCD_PLATFORM=y
CONFIG_SCSI_UFS_QCOM=y
CONFIG_PHY_QCOM_QMP=y
CONFIG_PHY_QCOM_QMP_UFS=y
```

DTB model, compatible strings and size match the hand-off assertions. The
kernel-bundled `dtc` emits inherited warnings while decompiling the fully
resolved tree (duplicate disabled GENI unit addresses and other base-DTS
warnings); the targeted schema build itself completes without an error.

## Artifacts

- `out/arch/arm64/boot/Image`: 58,763,776 bytes,
  SHA-256 `f911a6f8a209d75387ac2881b0e160d102a4cc5e25fb3de398941b4a7cb90a1e`
- `out/arch/arm64/boot/dts/qcom/x1p42100-samsung-galaxy-book4-edge.dtb`:
  213,430 bytes,
  SHA-256 `1287aee365bb3c2fc88dea9ad9677567677795d5c5d419d3449cc99d72650036`
- `out/.config`: SHA-256
  `09e28cd69147a3136dbac5ac1dcc8e34a9b2f833debecf874f1ff030551217d4`
- Staged module tree: `out/modules-root`
- Sorted module-tree manifest: `out/modules-manifest.txt`, SHA-256
  `295188857e5b896f635b42393461952d28ce6758a9275914d7094b263e0d733a`

The generated module-signing key is ephemeral build output and is not a
deployment trust decision.

## Firmware inventory

The resolved board DTB contains these firmware names:

```text
qcom/x1e80100/adsp.mbn
qcom/x1e80100/adsp_dtb.mbn
qcom/x1e80100/cdsp.mbn
qcom/x1e80100/cdsp_dtb.mbn
```

They were not found in the workstation's current firmware tree. They have not
been copied from an X1E device or reference repository because compatibility
with this X1P42100 board has not been demonstrated. ADSP and CDSP remain
deferred for the first UFS/USB/initramfs milestone.

## Boundary of this record

No removable or internal storage, EFI entry, firmware setting, proprietary
firmware or physical NP750XQA device was changed. Recovery-root and bootloader
packaging still require selecting an actual removable target and confirming
the Samsung UEFI DTB hand-off mechanism before any media is written.

## Experimental display build (2026-09-01)

The display branch was built and schema-validated on the Arch workstation.
The initial display defconfig requested `CONFIG_DRM_MSM=y`, but Kconfig reduced
it to `m` because `QCOM_AOSS_QMP`, `QCOM_LLCC` and `QCOM_OCMEM` were modules.
Those three dependencies were changed to built-in so MSM DRM and its selected
DRM helpers genuinely resolve to `y`.

The following all resolve built-in in the installed configuration:

```text
CONFIG_DRM_MSM=y
CONFIG_DRM_EXEC=y
CONFIG_DRM_GPUVM=y
CONFIG_DRM_SCHED=y
CONFIG_DRM_PANEL_EDP=y
CONFIG_PHY_QCOM_EDP=y
CONFIG_QCOM_AOSS_QMP=y
CONFIG_QCOM_LLCC=y
CONFIG_QCOM_OCMEM=y
```

Both targeted `dt_binding_check` and `CHECK_DTBS=y` completed successfully with
dtschema 2026.6. The complete `Image` and module build also completed.

- Kernel release: `6.17.0-rc4+`
- `Image` SHA-256:
  `0b96cc5dfb140f8fca37fb8c9fba723a593493cf28c4a409071ed030ef6fcfd3`
- NP750XQA display DTB SHA-256:
  `cc445bb69e707ec737e39ee3898cfa1a58022df06fb0bf59443e9d2f579478d8`
- Resolved `.config` SHA-256:
  `739226877eb80d1cf48e5335185335663cafa40b73928ca121ab6591b351b30e`
- Sorted module manifest SHA-256:
  `a18beeaef93441de099d9201acad22ccaeaf218d5a9ee514454aa8bb07700a48`

## Revised HPD/backlight source (2026-09-02)

After the built-in display build showed a few Linux messages and then the same
black screen, the DTS was compared with other Purwa LCD devices and with the
NP750XQA DSDT. Commit `65fe4cdbf3a52b6f01e5b806232fab8fe03619c7`
replaces `no-hpd` with the dedicated DP3 HPD pinctrl and adds the PMK8550 PWM
backlight described in
`SECOND_BOOT_RESULT.md`. `CONFIG_BACKLIGHT_PWM` and `CONFIG_LEDS_QCOM_LPG` are
requested built in.

The source DTB was compiled and semantically checked with the Windows snapshot:

- DTB size: 213826 bytes
- DTB SHA-256:
  `3317e3073d483911d7f985591e2d1aa26908dc65ffee869520b97cfc56472057`

This is not a replacement for the build record above. A native Linux build must
still resolve Kconfig, run the DT schema checks and produce new hashes for the
Image, DTB, `.config` and module manifest before updating recovery media.

## USB-A corrected source (2026-09-02)

After tracing the recovery stick to ACPI `USB3/RHUB/MP1`, the source was
changed in commit `25c1771b1` as documented in `USB_BRINGUP.md`. A
Windows-hosted preprocessing,
`dtc` compilation, DTB round trip and targeted semantic validation completed.
Assertions cover the enabled `i2c18` bus, new `nxp,ptn3222` node, disabled CRD
repeater and the `usb_mp_hsphy1` phandle link.

- DTB size: 214337 bytes
- DTB SHA-256:
  `16cdcd18574c7c3d536ccfb0536c7e22dcecac0ad308bdbd3e823ee803d36c5e`

The initial Windows MSYS2 Kconfig attempt did not complete. During the
follow-up USB dependency audit, `book4_defconfig` was resolved successfully
with the kernel's own Kconfig tools in a native AArch64 WSL environment. The
21 USB-root and diagnostic-console checks in
`recovery/check-usb-root-config.sh` all resolved to `y`, including GCC, TCSR,
TLMM, RPMh regulator, interconnect and GPI DMA providers that the first fix
had still left modular or unset. A native Arch build must still run schema
validation and produce the final Image, DTB, initramfs and configuration
hashes before recovery media is updated.
