#!/bin/bash
# run ftr
if [ -e /scripts/upd_hist/ftr-configured ]
 then
  # already setup this Pi.
  clear
else
   chvt 1
   clear
   initctl stop xbmc
   #remove botched update
   rm ftr.sh > /dev/null 2>&1
   # get ftr script
   logger -t update-checker "Downloading ftr.sh"
   wget -q $srcbase/first-time-run/ftr.sh
   chmod +x ftr.sh
   . ./ftr.sh
   logger -t update-checker "Updated ftr.sh"
fi
# Check for service updates

if [ ! -e /scripts/upd_hist/.031301 ]
then
chvt 1
clear
initctl stop xbmc
# remove botched update
rm dosysupd.sh > /dev/null 2>&1
logger -t update-checker "Downloading 031301 update"
# install March13 rootfs patches
wget -q $srcbase/update-system/system/upd_sysfs-031301.sh -O /scripts/upd_sys/dosysupd.sh
chmod +x /scripts/upd_sys/dosysupd.sh
. /scripts/upd_sys/dosysupd.sh
rm /scripts/upd_sys/dosysupd.sh
fi

if [ ! -e /scripts/upd_hist/.041322 ]
then
chvt 1
clear
initctl stop xbmc
# remove botched update
rm dosysupd.sh > /dev/null 2>&1
logger -t update-checker "Downloading 041322 update"
# install April13 rootfs patches
wget -q $srcbase/update-system/system/upd_sysfs-041322.sh -O /scripts/upd_sys/dosysupd.sh
chmod +x /scripts/upd_sys/dosysupd.sh
. /scripts/upd_sys/dosysupd.sh
rm /scripts/upd_sys/dosysupd.sh
fi

