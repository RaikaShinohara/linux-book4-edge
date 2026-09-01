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
