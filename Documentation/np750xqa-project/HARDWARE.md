# NP750XQA hardware evidence

This file records non-unique hardware facts captured from the machine. Serial
numbers, MAC addresses and other machine-unique identifiers are intentionally
excluded.

## Platform

- Product: Samsung Galaxy Book4 Edge `NP750XQA-KB1ES`.
- Board family: `SGLB750A27-C01-G001-S0001`.
- System SKU: `GALAXY A5A5-PVQA`.
- SoC: Qualcomm Snapdragon X Plus `X1P42100`, eight Oryon CPU cores.
- GPU: Adreno X1-45.
- RAM: 16 GiB.
- Firmware platform identity: `SCP_PURWA`, `CRD08380`.

## Storage

- Internal storage: Kioxia `THGJFJT1E45BATPA`, 256 GB UFS.
- ACPI device: `QCOM24A5`.
- UFS controller physical base: `0x01d84000`.
- The Samsung X1E regulator assignments match the observed UFS topology and
  are present in the initial DTS.
- The X1E-specific `reset-gpios = <&tlmm 238 ...>` property is deliberately
  omitted because it has not been confirmed on NP750XQA.

## Display

- EDID manufacturer: KDB.
- EDID product: `0x0526`.
- Panel text: `KD156N2030A03`.
- Native mode: 1920x1080 at approximately 60 Hz.
- Size: 15.6 inches, approximately 34 x 19 cm.
- The DSDT panel profile selects eDP, dynamic EDID/DPCD reads, active-high HPD,
  zero milliseconds of power-up wait and a 19.2 kHz, 9-bit PMIC backlight.
- DSDT power resources vote the DP3 clocks and the 1.2 V/0.8 V PHY rails.
- The ATNA panel inherited from the X1 CRD is incompatible. The experimental
  DTS replaces only that panel with `edp-panel`, retains the standard X1 eDP
  controller, PHY and 3.3 V rail, and removes the ATNA backlight-enable GPIO.
- Native video and backlight control remain untested. The generic driver may
  preserve the firmware-selected brightness even if Linux cannot adjust it.

## Input and EC

- Keyboard: Samsung `SSEC0001`, HID-over-I2C.
  - ACPI controller `I2C1`, Linux Device Tree controller `i2c0`.
  - I2C address `0x05`, 400 kHz.
  - HID descriptor address `0x20`.
  - ACPI GPIO resource `0x0180`.
  - The matching Samsung mapping resolves to TLMM GPIO 67, level low.
- Touchpad: Zinitix `ZNT0001`, HID-over-I2C.
  - ACPI controller `IC14`, Linux Device Tree controller `i2c13`.
  - I2C address `0x40`, 400 kHz.
  - ACPI GPIO resource `0x03c0`.
  - HID descriptor address is the runtime ACPI NVS byte `TPDO`; it is unknown.
  - The touchpad must remain undescribed until the descriptor address and TLMM
    interrupt mapping are confirmed from Linux or a safe firmware evaluation.
- Embedded controller: Samsung `SAM060B`.
  - Endpoint `0x62` on ACPI `I2C6`.
  - Endpoint `0x64` on ACPI `I2C1`.
  - No EC driver has been integrated for this board.

ACPI I2C controller numbers are one-based while the current Linux DTS aliases
are zero-based. For example, ACPI `I2C1` maps to DTS `i2c0`, and ACPI `IC14`
maps to DTS `i2c13`.

## Other devices

- WLAN: Qualcomm FastConnect 7800, PCI ID `17cb:1107`.
- Audio subsystem ID: `CA09144D`.
- Camera: USB camera plus Qualcomm Spectra platform devices; CAMSS remains
  disabled because the sensor path is not confirmed.
- Fingerprint reader: EgisTec USB device; not described in the DTS.

## Evidence retained outside Git

The following diagnostic captures existed in the original local workspace but
were not committed because firmware tables can contain OEM or machine-specific
data:

- DSDT AML SHA-256:
  `AF980621A2FEAA6D8B6720B577A6F6D124734129D1C0C0EC0974B123AABFD9FE`.
- FADT binary SHA-256:
  `28BF9E91CDC83159F8EC4D48EE71BBEBEDF600CF833E30C995320B2363C99C07`.
- EDID SHA-256:
  `94814A6E5DD47AF8F09B47A4A54CE5063525CB06F19F9994FB89A9807B30A410`.

If those files are transferred to the Arch workstation, review them for unique
data before publishing them.
