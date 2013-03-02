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
  ./ftr.sh
   logger -t update-checker "Updated ftr.sh"
fi
