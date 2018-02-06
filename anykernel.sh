# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() {
kernel.string=Flash Kernel for the OnePlus 5/T by @nathanchance
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus5
device.name2=OnePlus5T
device.name3=cheeseburger
device.name4=dumpling
device.name5=
} # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;

# Alert of unsupported Android version
android_ver=$(grep "^ro.build.version.release" /system/build.prop | cut -d= -f2);
case "$android_ver" in
  "8.0.0"|"8.1.0") support_status="supported";;
  *) support_status="unsupported";;
esac;
ui_print " ";
ui_print "Running Android $android_ver..."
ui_print "This kernel is $support_status for this version!";

if [ -f /tmp/anykernel/version ]; then
  ui_print " ";
  ui_print "Kernel version: $(cat /tmp/anykernel/version)";
fi;

## AnyKernel install
dump_boot;

# begin ramdisk changes
rm $ramdisk/init.oem.early_boot.sh
rm $ramdisk/init.oem.engineermode.sh
chmod 755 $ramdisk/*.sh
chmod 644 $ramdisk/*.rc
chmod 775 $ramdisk/res
mkdir -p $ramdisk/res/asset
chmod 755 $ramdisk/res/busybox
for i in $($ramdisk/res/busybox --list); do ln -s /res/busybox $ramdisk/res/asset/$i; done
find $ramdisk/lib -type d -exec chmod 775 {} \;
find $ramdisk/lib -type f -exec chmod 664 {} \;
ln -s /persist/wlan_mac.bin $ramdisk/lib/firmware/overrides/wlan/qca_cld/wlan_mac.bin

# Set the default background app limit to 60
insert_line default.prop "ro.sys.fw.bg_apps_limit=60" before "ro.secure=1" "ro.sys.fw.bg_apps_limit=60";

# sepolicy
$bin/sepolicy-inject -s init -t rootfs -c file -p execute_no_trans -P sepolicy;
$bin/sepolicy-inject -s init -t rootfs -c system -p module_load -P sepolicy;
$bin/sepolicy-inject -s init -t system_file -c file -p mounton -P sepolicy;
$bin/sepolicy-inject -s init -t vendor_configs_file -c file -p mounton -P sepolicy;
$bin/sepolicy-inject -s init -t vendor_file -c file -p mounton -P sepolicy;
$bin/sepolicy-inject -s init -t device -c lnk_file -p setattr -P sepolicy;
$bin/sepolicy-inject -s modprobe -t rootfs -c system -p module_load -P sepolicy;
$bin/sepolicy-inject -s shell -t kmsg_device -c chr_file -p read,write,open -P sepolicy;
$bin/sepolicy-inject -s shell -t device -c dir -p read,write,open,add_name -P sepolicy;
$bin/sepolicy-inject -s shell -t rootfs -c dir -p read,write,open,add_name -P sepolicy;
$bin/sepolicy-inject -s shell -t vendor_file -c dir -p mounton -P sepolicy;
$bin/sepolicy-inject -s shell -t sysfs -c file -p setattr -P sepolicy;
$bin/sepolicy-inject -s shell -t shell -c capability -p chown,sys_admin -P sepolicy;

# sepolicy_debug
$bin/sepolicy-inject -s init -t rootfs -c file -p execute_no_trans -P sepolicy_debug;
$bin/sepolicy-inject -s init -t rootfs -c system -p module_load -P sepolicy_debug;
$bin/sepolicy-inject -s init -t system_file -c file -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s init -t vendor_configs_file -c file -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s init -t vendor_file -c file -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s init -t device -c lnk_file -p setattr -P sepolicy_debug;
$bin/sepolicy-inject -s modprobe -t rootfs -c system -p module_load -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t kmsg_device -c chr_file -p read,write,open -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t device -c dir -p read,write,open,add_name -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t rootfs -c dir -p read,write,open,add_name -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t vendor_file -c dir -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t sysfs -c file -p setattr -P sepolicy_debug;
$bin/sepolicy-inject -s shell -t shell -c capability -p chown,sys_admin -P sepolicy_debug;

# end ramdisk changes

write_boot;

## end install

