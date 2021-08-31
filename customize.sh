#!/bin/bash
set -euo pipefail

IMGFILE="CentOS-Stream-8-x86_64-latest-dvd1.iso"
#DUDFILE="dd-megaraid_sas-07.714.04.00-3.el8_4.elrepo.iso"

if ! [[ "$#" -eq "2" ]]; then
    echo "Usage: $0 <kickstart> <output file>"
    exit 1
fi

KICKSTART="$(realpath "$1")"
OUTFILE="$(realpath "$2")"

test -f "$KICKSTART" || (echo "Error: $1 doesn't exist"; exit 1)
test -f "$OUTFILE" && (echo "Error: $2 exists"; exit 1)

MOUNTPOINT="$(mktemp -d)"
BUILDDIR="$(mktemp -d)"

test -d cache || mkdir cache

pushd cache
test -f "$IMGFILE" || wget "http://ftp.funet.fi/pub/mirrors/centos.org/8-stream/isos/x86_64/$IMGFILE"
#test -f "$DUDFILE" || wget "https://elrepo.org/linux/dud/el8/x86_64/$DUDFILE"

sudo mount -o loop "$IMGFILE" "$MOUNTPOINT"
echo "Mounted image at $MOUNTPOINT"

shopt -s dotglob
echo "Building at $BUILDDIR"
cp -aRf "$MOUNTPOINT"/* "$BUILDDIR"

#echo "Inserting DUD"
#chmod +w "$BUILDDIR/images/pxeboot/initrd.img"
#echo "./$DUDFILE" | cpio -H newc -o | gzip >> "$BUILDDIR/images/pxeboot/initrd.img"

popd

echo "Copying kickstart"
cp "$KICKSTART" "$BUILDDIR/ks.cfg"

echo "Creating bootloader entry"
chmod +w "$BUILDDIR/EFI/BOOT/grub.cfg"
echo "
menuentry 'Install CentOS Stream 8-stream (custom kickstart)' --class fedora --class gnu-linux --class gnu --class os {
	linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS-Stream-8-x86_64-dvd inst.ks=cdrom:/ks.cfg
	initrdefi /images/pxeboot/initrd.img
}
" >> "$BUILDDIR/EFI/BOOT/grub.cfg"

echo "Creating custom repo"
mkdir "$BUILDDIR/custom_rpm"
cp packages/*.rpm "$BUILDDIR/custom_rpm/"
pushd "$BUILDDIR/custom_rpm/"
createrepo .
popd

echo "Building ISO"
pushd "$BUILDDIR"
chmod +w isolinux/isolinux.bin
genisoimage -o "$OUTFILE" -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot \
    -e images/efiboot.img -no-emul-boot -graft-points \
    -V "CentOS-Stream-8-x86_64-dvd" .
isohybrid --uefi "$OUTFILE"

chmod -R +w "$BUILDDIR"
rm -rf "$BUILDDIR"
sudo umount "$MOUNTPOINT"
rmdir "$MOUNTPOINT"

echo "Built: $OUTFILE"
