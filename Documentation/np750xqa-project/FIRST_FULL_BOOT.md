# Llegar al primer Linux completo: NP750XQA

Continuación del 2026-09-07 en `codex/np750xqa-usb-test-3`.
Leer junto a [USB_TEST_3.md](USB_TEST_3.md). El objetivo inmediato es arrancar
Arch Linux ARM desde el pendrive, iniciar systemd y llegar a una consola de
login. No requiere un escritorio ni instalar Linux en la UFS interna.

## Qué sabemos y qué falta

El historial de pruebas registra una shell del initramfs con teclado funcional.
Eso demuestra ejecución de userspace temprano. Falta demostrar que Linux
enumera el pendrive, monta su raíz ext4 y ejecuta el sistema instalado en ella.
GRUB lleva Image/initramfs/DTB dentro de su propio EFI: que los cargue no prueba
el funcionamiento del controlador USB de Linux.

Esta revisión añade:

- Comprobación de 22 dependencias USB/consola y otras 38 para initramfs,
  particiones, systemd, consola, proveedores Qualcomm y logs FAT.
- `CONFIG_NLS_ISO8859_1=y`: es el charset predeterminado de VFAT en esta
  configuración. Antes era módulo. Evita una dependencia modular del log
  temprano; no demuestra que faltase en los initramfs anteriores.
- Arranque explícito a `multi-user.target`, mensajes de estado de systemd,
  `rootfstype=ext4` y un buffer de log del kernel de 4 MiB.
- Entrada con `init=/bin/sh` para probar la raíz real antes de systemd.
- Logger con salida a journal/consola y límite de inicio de 30 segundos para
  que una recopilación lenta no prolongue indefinidamente su trabajo.
- `check-rootfs.sh`, una comprobación sin cambios ejecutada dentro de la raíz
  ARM64 preparada: binarios, bibliotecas al ejecutarlos, fstab, logger y login.

## 1. Preparar un conjunto coherente en el PC Arch

Usar un checkout limpio en un filesystem Linux sensible a mayúsculas. No
compilar desde la antigua carpeta temporal de la microSD: se observaron errores
FAT allí. La microSD de trabajo y el Kingston de arranque son dispositivos
distintos; ese hallazgo no demuestra corrupción del pendrive.

Desde la raíz del repositorio, con las dependencias del proyecto instaladas:

```sh
make O=out-usb3 ARCH=arm64 LLVM=1 book4_defconfig
sh Documentation/np750xqa-project/recovery/check-first-boot-config.sh out-usb3/.config
make O=out-usb3 ARCH=arm64 LLVM=1 -j"$(nproc)" Image modules \
  qcom/x1p42100-samsung-galaxy-book4-edge.dtb \
  qcom/x1p42100-samsung-galaxy-book4-edge-recovery.dtb
make -s O=out-usb3 ARCH=arm64 LLVM=1 kernelrelease
```

El checker necesita la `.config` resuelta, no el defconfig resumido. Registrar
commit, versión resultante y hashes. Instalar los módulos en la raíz ARM64
externa para ESA versión y ejecutar depmod para ella. No usar `uname -r` del
PC como versión del kernel del portátil. Copiar también `modules.builtin` y
`modules.builtin.modinfo` mediante la instalación normal de módulos.

Antes de escribir al medio, identificarlo por transporte USB, modelo, tamaño
y UUID. Comprobar sus particiones desmontadas con `e2fsck -fn` y `fsck.fat -n`
sobre los dispositivos exactos identificados. Resolver cualquier corrupción
antes de atribuir un fallo de montaje a la PHY. Estas comprobaciones no deben
dirigirse a particiones internas ni a la microSD de trabajo por confusión.

## 2. Preparar y comprobar la raíz ARM64

Copiar `recovery/` a un directorio de preparación de la raíz externa, por
ejemplo `/opt/np750-recovery`. Los comandos siguientes se ejecutan DENTRO
de ese root/chroot AArch64. En el i9 hace falta el soporte QEMU/binfmt del
procedimiento anterior. No sirven los binarios x86-64 del host.

```sh
RECOVERY=/opt/np750-recovery
for hook in np750udev np750log; do
  install -Dm755 "$RECOVERY/initcpio-install-$hook" "/etc/initcpio/install/$hook"
  install -Dm755 "$RECOVERY/initcpio-hook-$hook" "/etc/initcpio/hooks/$hook"
done
install -Dm755 "$RECOVERY/np750-firstboot-log" /usr/local/sbin/np750-firstboot-log
install -Dm644 "$RECOVERY/np750-firstboot-log.service" /etc/systemd/system/np750-firstboot-log.service
systemctl --root=/ enable np750-firstboot-log.service getty@tty1.service
mkdir -p /boot/efi /var/log/np750xqa /var/log/journal
```

Revisar fstab contra la plantilla: raíz ext4 por UUID externo, opciones que
permitan remontarla rw, ESP externa `noauto,ro`, ninguna UFS ni swap interna.
Crear o comprobar la cuenta de login y poner su contraseña de forma interactiva
con `passwd`; no dejar el acceso sujeto a una contraseña desconocida o cuenta
bloqueada. Mantener la configuración de red/SSH deshabilitada del primer test.

Ejecutar dentro del chroot, sustituyendo UUIDs y cuenta si cambiaron:

```sh
bash /opt/np750-recovery/check-rootfs.sh \
  c2bc9dc2-bdf2-4d87-9225-7c0b6d44a52e 2A8E-8A5D alarm
```

`systemd --version` y `udevd --version` deben poder ejecutarse. Un ELF presente
puede fallar si falta `/lib/ld-linux-aarch64.so.1` o una biblioteca; comprobar
solo que el archivo existe no basta. El checker no inicia systemd ni prueba
todos sus servicios. Si una unidad o login falla, corregirlo en la raíz y
repetir el preflight antes de volver a probar hardware.

## 3. Initramfs y EFI: inspeccionar lo que realmente se va a arrancar

Generar mkinitcpio dentro del root ARM64 con `-k` fijado a la versión recién
compilada y el `mkinitcpio-np750xqa.conf` actualizado. Cualquier error de
construcción debe resolverse antes del empaquetado.

Extraer el initramfs con `lsinitcpio` en un directorio temporal vacío. Revisar:

- `/init` y BusyBox ash ejecutables; `switch_root`, mount, blkid/findfs, timeout
  y sus bibliotecas presentes.
- `/hooks/np750udev` y `/hooks/np750log` ejecutables (0755), con contenido igual
  al de esta rama. `add_runscript` busca scripts ejecutables al construirlos.
- `/config` generado contiene np750log en early, regular, late y emergency
  hooks, y np750udev en early/regular/cleanup. No añadir también el hook udev
  estándar ni el de systemd a esta receta de initramfs BusyBox.
- No queda un `np750earlybreak` activo por accidente en el arranque automático.
- La versión de módulos corresponde a Image. Los drivers integrados no tienen
  por qué aparecer como archivos `.ko` dentro del initramfs.
- Los UUID de GRUB/fstab/particiones coinciden. `np750.loguuid=` permite cambiar
  el destino del logger si se sustituyó la ESP; su valor por defecto sigue
  siendo `2A8E-8A5D`.

Reconstruir el EFI autocontenido siguiendo [USB_TEST_3.md](USB_TEST_3.md).
Actualizar archivos sueltos en la FAT no modifica las copias ya incrustadas
en `BOOTAA64.EFI`. Conservar el EFI anterior con otro nombre y comprobar el
menú con `grub-script-check`. Registrar hashes del EFI, Image, los dos DTB,
initramfs y configuración. No ejecutar grub-install sobre almacenamiento
interno ni modificar el arranque permanente de Windows.

## 4. Orden de las pruebas físicas

1. **Automática MP1:** debería continuar hacia systemd y un login de texto.
   Registrar la etiqueta exacta del menú y varios minutos de vídeo. Los 90 s
   de `rootdelay` son por resolución de dispositivo en mkinitcpio, no un plazo
   total de arranque. Puede haber varias esperas.
2. **Premount shell:** demuestra initramfs, antes de montar la raíz. Revisar
   `dmesg`, `/sys/kernel/debug/devices_deferred`, `/dev/disk/by-uuid` y
   `/run/initramfs/np750xqa`. Aquí `exit` continúa el arranque.
3. **Real-root shell before systemd:** `init=/bin/sh` conserva la misma ruta
   USB, monta la raíz y ejecuta su shell como PID 1. Si aparece, comprobar
   `/proc/mounts`, `/etc/os-release`, `/proc/1/comm` y `/sbin/init --version`.
   Para continuar escribir `exec /sbin/init`. NO escribir `exit`: terminar
   PID 1 puede provocar un kernel panic. El logger de systemd no se ejecuta
   mientras se permanezca en esta shell.
4. **fw_devlink on comparison:** cambia únicamente ese ajuste frente al test
   automático, manteniendo artefactos, puerto y pendrive. Sirve para contrastar
   la hipótesis de orden de proveedores; no demuestra por sí solo un ciclo.
5. Probar eDP nativo después de establecer el avance de la raíz externa.

Desde la shell temprana, los mensajes de `a400000.usb`, `88e5000.phy`, GENI,
PTN3222 y reguladores permiten localizar el primer proveedor pendiente. Si el
dispositivo USB aparece pero no hay particiones, investigar tabla de particiones
y SCSI. Si existe el UUID y falla ext4, investigar el filesystem. Si la shell
de la raíz funciona y systemd falla, investigar el rootfs y sus servicios.

`ro` solicita un primer montaje de raíz de solo lectura, pero fsck puede
reparar el filesystem antes y systemd puede remontarlo rw después. No equivale
a un arranque sin escrituras. Los logs persistentes necesitan un destino rw.

## 5. Evidencia que confirma el resultado

`early-initramfs` demuestra hooks tempranos. `before-root-resolution` demuestra
que acabaron los hooks anteriores. `after-root-mount-attempt` NO garantiza
montaje: mirar `mounts.txt` y el dispositivo de `/sysroot`. `stage.txt` del
logger demuestra ejecución en la raíz real. Para confirmar el objetivo final,
iniciar sesión y recoger:

```sh
findmnt /
cat /proc/1/comm
systemctl is-active multi-user.target
systemctl --failed --no-pager
systemctl list-jobs --no-pager
cat /sys/devices/system/cpu/online
journalctl -b --no-pager
```

Guardar los logs de `/var/log/np750xqa/` y los de la ESP independientemente.
Una pantalla negra, un LED inactivo o ausencia de logs no identifican por sí
solos la fase del fallo. Los logs solo en RAM se pierden al apagar. No hay
evidencia actual que justifique cambiar EL2, PSCI o la topología de CPUs.

## Validación realizada en el laboratorio local

- `git fsck --full --no-reflogs` terminó sin errores de integridad de objetos.
  Informó de un commit no referenciado, que se conserva.
- Kconfig ejecutado realmente en AArch64 con GCC 14.2; las 60 comprobaciones
  de dependencias y las de command line/charset pasan en la `.config` resuelta.
  El árbol actual corresponde a Linux 6.17.0-rc4. La configuración generada
  localmente tiene SHA-256
  `96ce705d6813d13e2ab3386d0140104ed42c0590a669415edfae48c988bcd115`.
  La configuración generada con LLVM en Arch debe volver a pasar el checker.
- Pruebas negativas: el checker rechaza volver a dejar el charset FAT como
  módulo y rechaza `CONFIG_CMDLINE_FORCE=y`. El checker del rootfs pasa la
  comprobación de sintaxis Bash; su ejecución sobre el medio ARM64 real está
  pendiente, por lo que aún no certifica ese rootfs.
- BusyBox ash ejecutó las pruebas del logger en el trabajo anterior. La nueva
  receta no cambia la topología ni los scripts de captura del initramfs.
- Ambos DTB compilados con DTC 1.7.2; dtschema 2026.6 validó sin mensajes los
  esquemas seleccionados de placa Qualcomm, PTN3222, Synopsys eUSB2 y panel eDP.
  Esto no equivale a pasar todos los esquemas de todos los dispositivos.
- El checker de rootfs está preparado para el medio real. Ese medio no está
  conectado aquí: no se ha confirmado su contenido, login ni integridad actual.
- Falta compilar el nuevo Image/módulos/initramfs y efectuar el arranque físico.
  Los cambios reducen dependencias y añaden diagnósticos, no garantizan USB o LCD.
- `grub-script-check` 2.12 acepta el menú. Los hooks np750log y los nuevos
  checkers se guardan también con permiso ejecutable en Git; al instalarlos
  en la raíz ARM64 se sigue usando explícitamente el modo 0755.

Referencias consultadas: [requisitos de systemd](https://github.com/systemd/systemd/blob/main/README),
[montaje y fsck de mkinitcpio](https://github.com/archlinux/mkinitcpio/blob/master/init_functions),
[os-release de Arch Linux ARM](https://github.com/archlinuxarm/PKGBUILDs/blob/master/core/filesystem/os-release).
