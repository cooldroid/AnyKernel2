# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() {
kernel.string=Franco Kernel by franciscofranco @ xda-developers
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=OnePlus5
device.name2=cheeseburger
device.name3=OnePlus5T
device.name4=dumpling
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
chmod 644 $ramdisk/modules/*;
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

# AnyKernel permissions
chmod 755 $ramdisk/sbin/busybox
chmod -R 755 $ramdisk/res/bc
chmod -R 755 $ramdisk/res/misc

# Set the default background app limit to 60
insert_line default.prop "ro.sys.fw.bg_apps_limit=60" before "ro.secure=1" "ro.sys.fw.bg_apps_limit=60";

# sepolicy
$bin/sepolicy-inject -s modprobe -t rootfs -c system -p module_load -P sepolicy;
$bin/sepolicy-inject -s init -t vendor_file -c file -p mounton -P sepolicy;
$bin/sepolicy-inject -s init -t system_file -c file -p mounton -P sepolicy;
$bin/sepolicy-inject -s init -t rootfs -c file -p execute_no_trans -P sepolicy;
$bin/sepolicy-inject -s init -t rootfs -c system -p module_load -P sepolicy;

# sepolicy_debug
$bin/sepolicy-inject -s modprobe -t rootfs -c system -p module_load -P sepolicy;
$bin/sepolicy-inject -s init -t vendor_file -c file -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s init -t system_file -c file -p mounton -P sepolicy_debug;
$bin/sepolicy-inject -s init -t rootfs -c file -p execute_no_trans -P sepolicy_debug;
$bin/sepolicy-inject -s modprobe -t rootfs -c system -p module_load -P sepolicy_debug;

# systemless module load
chmod 755 $ramdisk/modules
find $ramdisk/modules -type f -exec chmod 644 {} \;
ln -s /system/lib/modules/qca_cld3/qca_cld3_wlan.ko  $ramdisk/modules/wlan.ko
insert_line plat_file_contexts "\/modules" after "\/res(\/.*)?		u:object_r:rootfs:s0" "\/modules(\/.*)?		u:object_r:system_file:s0"
modblock='\n    restorecon_recursive \/modules'
#for mod in $(ls $ramdisk/modules); do
#  modblock="${modblock}\n    mount none /modules/${mod} /system/lib/modules/${mod} bind"
#done
modblock="${modblock}\n    mount none /modules /system/lib/modules bind"
replace_string init.rc "\/modules" "trigger fs" "trigger fs$modblock";

# end ramdisk changes

write_boot;

## end install

