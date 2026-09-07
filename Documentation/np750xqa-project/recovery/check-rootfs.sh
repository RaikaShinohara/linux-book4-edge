#!/bin/bash
# Run INSIDE the prepared Arch Linux ARM root/chroot; never starts PID 1.
set -u
export LC_ALL=C
if [[ $# -ne 3 || $1 == --help ]]; then
    echo "Usage (inside ARM64 root): bash $0 ROOT_UUID EFI_UUID LOGIN_USER"
    echo 'Read-only preflight. Requires readelf, systemctl, systemd-analyze, getent and passwd.'
    exit 2
fi
root_uuid=$1
efi_uuid=$2
login_user=$3
failed=0
fail() { echo "FAIL: $*" >&2; failed=1; }
for cmd in readelf systemctl systemd-analyze getent passwd awk; do
    command -v "$cmd" >/dev/null || fail "missing tool: $cmd"
done
[[ $failed == 0 ]] || exit 1
grep -Eq '^ID=(archarm|"archarm")$' /etc/os-release || {
    echo 'FAIL: run this inside the prepared Arch Linux ARM root, not the workstation or Alpine lab' >&2
    exit 1
}
for binary in /sbin/init /usr/lib/systemd/systemd-udevd /bin/sh; do
    if [[ ! -x $binary ]]; then
        fail "missing executable: $binary"
        continue
    fi
    readelf -h "$binary" | grep -q 'Machine:.*AArch64' || fail "not AArch64 ELF: $binary"
done
# These commands exercise the actual dynamic loader and library dependencies.
/sbin/init --version || fail 'systemd or its libraries cannot execute'
/usr/lib/systemd/systemd-udevd --version || fail 'udevd or its libraries cannot execute'
/bin/sh -c 'exit 0' || fail 'root shell or its libraries cannot execute'
awk -v wanted="UUID=$root_uuid" '
    /^[[:space:]]*#/ || NF == 0 { next }
    $2 == "/" { n++; if ($1 != wanted || $3 != "ext4" || $4 ~ /(^|,)ro(,|$)/) bad=1 }
    END { exit !(n == 1 && !bad) }
' /etc/fstab || fail 'fstab must have exactly one external UUID root, ext4, allowing rw remount'
awk -v wanted="UUID=$efi_uuid" '
    /^[[:space:]]*#/ || NF == 0 { next }
    $2 == "/boot/efi" { n++; if ($1 != wanted || $3 != "vfat" || $4 !~ /(^|,)noauto(,|$)/) bad=1 }
    $2 != "/" && $2 != "/boot/efi" { bad=1 }
    END { exit !(n == 1 && !bad) }
' /etc/fstab || fail 'fstab differs from the external-root/optional-ESP layout; inspect every extra mount'
[[ -d /boot/efi ]] || fail 'missing /boot/efi mountpoint'
[[ -x /usr/local/sbin/np750-firstboot-log ]] || fail 'missing executable firstboot logger'
unit=/etc/systemd/system/np750-firstboot-log.service
[[ -f $unit ]] || fail "missing $unit"
systemd-analyze verify --man=no "$unit" || fail 'systemd unit verification failed'
systemctl --root=/ is-enabled np750-firstboot-log.service || fail 'firstboot logger is not enabled'
systemctl --root=/ is-enabled getty@tty1.service || fail 'tty1 login service is not enabled'
account=$(getent passwd "$login_user") || account=''
if [[ -z $account ]]; then
    fail "login account missing: $login_user"
else
    shell=${account##*:}
    case "$shell" in */false|*/nologin) fail 'login shell denies access' ;; esac
    [[ -x $shell ]] || fail "login shell not executable: $shell"
    password_state=$(passwd -S "$login_user" 2>/dev/null | awk '{print $2}')
    [[ $password_state == P ]] || fail 'login account needs an unlocked, nonempty password set interactively'
fi
[[ $failed == 0 ]] || exit 1
echo 'PASS: rootfs executables, fstab, logger and tty1 login prerequisites.'
echo 'Still required: matched kernel/modules/initramfs/DTB, filesystem integrity and physical USB boot.'
