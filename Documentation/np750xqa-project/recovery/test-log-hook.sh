#!/bin/sh
# Userspace control-flow test, not a substitute for BusyBox/initramfs/hardware.
# Never mounts disks. All proc/sys/dev/run paths are redirected to a fixture.
set -eu
src=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/np750-log-test.XXXXXX")
printf 'Fixture retained for inspection: %s\n' "$fixture"
sed -e 's|/proc/sys/|PROC_SYS_FIXTURE/|g' \
    -e "s|/proc/|$fixture/proc/|g" \
    -e "s|/sys/|$fixture/sys/|g" \
    -e "s|/run/|$fixture/run/|g" \
    -e "s|/dev/|$fixture/dev/|g" \
    -e "s|PROC_SYS_FIXTURE/|$fixture/proc/sys/|g" \
    "$src/initcpio-hook-np750log" >"$fixture/hook"
mkdir -p "$fixture/proc/sys/kernel/random" "$fixture/sys/kernel/debug" \
    "$fixture/sys/class/block" "$fixture/dev/disk/by-uuid" \
    "$fixture/sys/bus/usb/devices/1-1" "$fixture/run/initramfs"
printf 'test-boot\n' >"$fixture/proc/sys/kernel/random/boot_id"
printf '12.34 10.00\n' >"$fixture/proc/uptime"
printf 'root=UUID=test ro\n' >"$fixture/proc/cmdline"
: >"$fixture/proc/mounts"
printf 'a400000.usb waiting for supplier\n' >"$fixture/sys/kernel/debug/devices_deferred"
printf '0951\n' >"$fixture/sys/bus/usb/devices/1-1/idVendor"
printf 'early init log\n' >"$fixture/run/initramfs/init.log"
. "$fixture/hook"
getarg() { :; }
dmesg() { echo 'mock kernel log'; }
findfs() {
    [ "$1" = UUID=2A8E-8A5D ] || return 1
    [ "$scenario" != absent ] || return 1
    echo "$fixture/dev/sda1"
}
readlink() {
    case "$2" in
        */sys/class/block/*)
            if [ "$scenario" = internal ]; then
                echo /devices/platform/ufs/block/sda/sda1
            else
                echo /devices/platform/usb1/1-1/block/sda/sda1
            fi ;;
        *) echo "$2" ;;
    esac
}
# Execute mocks instead of mounting, unmounting or running real timeouts.
timeout() { shift 3; "$@"; }
mount() { echo mount >>"$fixture/actions"; [ "$scenario" != mountfail ]; }
umount() { echo umount >>"$fixture/actions"; }

ram=$fixture/run/initramfs/np750xqa
scenario=absent
np750_snapshot early-initramfs
test -f "$ram/early-initramfs/dmesg.txt"
test ! -f "$fixture/actions"
np750_snapshot before-root-resolution
test -f "$ram/before-root-resolution/usb-devices.txt"
grep -q 'idVendor: 0951' "$ram/before-root-resolution/usb-devices.txt"
test ! -f "$fixture/actions"
scenario=internal
np750_snapshot emergency
grep -q 'Refusing non-USB' "$ram/emergency/persist-error.txt"
test ! -f "$fixture/actions"
scenario=mountfail
np750_snapshot emergency
test "$(wc -l <"$fixture/actions")" -eq 1
scenario=usb
np750_snapshot after-root-mount-attempt
test -f "$fixture/run/np750-efi/np750xqa-early-logs/test-boot/early-initramfs/dmesg.txt"
test "$(wc -l <"$fixture/actions")" -eq 3
printf 'PASS: early RAM, absent ESP, USB inventory, internal refusal, mount failure, USB copy\n'
