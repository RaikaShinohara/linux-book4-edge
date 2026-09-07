#!/bin/sh
# Run on a Kconfig-resolved .config, not a sparse defconfig.
set -eu
config=${1:-out/.config}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$here/check-usb-root-config.sh" "$config"
required='ARM64 MMU BINFMT_ELF BLK_DEV_INITRD RD_GZIP
EFI EFI_STUB EFI_PARTITION MSDOS_PARTITION DEVTMPFS
PROC_FS SYSFS TMPFS CGROUPS FHANDLE INOTIFY_USER SIGNALFD TIMERFD EPOLL
NET UNIX UNIX98_PTYS TTY VT VT_CONSOLE FRAMEBUFFER_CONSOLE DEBUG_FS
USB_DWC3_HOST SCSI ARM_SMMU ARM_SMMU_QCOM QCOM_RPMH QCOM_COMMAND_DB QCOM_RPMHPD
FAT_FS VFAT_FS NLS_CODEPAGE_437 NLS_ISO8859_1'
failed=0
count=0
for symbol in $required; do
    count=$((count + 1))
    if ! grep -qx "CONFIG_${symbol}=y" "$config"; then
        echo "error: first-boot dependency CONFIG_${symbol} must be y" >&2
        failed=1
    fi
done
if grep -qx 'CONFIG_CMDLINE_FORCE=y' "$config"; then
    echo 'error: CONFIG_CMDLINE_FORCE would override the diagnostic GRUB command line' >&2
    failed=1
fi
if ! grep -qx 'CONFIG_FAT_DEFAULT_IOCHARSET="iso8859-1"' "$config"; then
    echo 'error: changed FAT charset; audit its built-in NLS dependency' >&2
    failed=1
fi
[ "$failed" -eq 0 ] || exit 1
echo "First-boot configuration passed ($count additional built-in symbols and command-line/charset checks)."
