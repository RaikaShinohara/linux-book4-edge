#!/bin/sh

set -eu

config=${1:-out/.config}

if [ ! -f "$config" ]; then
    echo "error: kernel configuration not found: $config" >&2
    exit 2
fi

required_symbols='CONFIG_CLK_X1E80100_GCC
CONFIG_CLK_X1E80100_TCSRCC
CONFIG_PINCTRL_X1E80100
CONFIG_REGULATOR_QCOM_RPMH
CONFIG_INTERCONNECT_QCOM_X1E80100
CONFIG_QCOM_GPI_DMA
CONFIG_I2C_QCOM_GENI
CONFIG_PHY_SNPS_EUSB2
CONFIG_PHY_NXP_PTN3222
CONFIG_PHY_QCOM_QMP_USB
CONFIG_USB_DWC3
CONFIG_USB_DWC3_QCOM
CONFIG_USB_XHCI_HCD
CONFIG_USB_XHCI_PLATFORM
CONFIG_USB_STORAGE
CONFIG_BLK_DEV_SD
CONFIG_EXT4_FS
CONFIG_HID
CONFIG_HID_GENERIC
CONFIG_I2C_HID_OF
CONFIG_USB_HID'

failed=0
count=0

for symbol in $required_symbols; do
    count=$((count + 1))
    if grep -qx "${symbol}=y" "$config"; then
        printf 'ok: %s=y\n' "$symbol"
    else
        actual=$(grep -E "^${symbol}=" "$config" || true)
        [ -n "$actual" ] || actual="$symbol is unset"
        printf 'error: expected %s=y; got %s\n' "$symbol" "$actual" >&2
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    exit 1
fi

printf 'USB-root and diagnostic-console configuration passed (%s symbols).\n' "$count"
