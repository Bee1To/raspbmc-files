#!/bin/bash
rm svcver > /dev/null 2>&1
wget -q $srcbase/update-system/xbmc-svcmgmt/svcver
if [ "$?" -ne 0 ]
then
        logger -t update-checker "Could not get svcmgmt diff file"  
        exit 1
fi
if diff svcver /scripts/upd_hist/svcver >/dev/null ; then
  logger -t update-checker "service management is up-to-date"
else
                chvt 1
                clear
                initctl stop xbmc
                logger -t update-checker "Downloading service management"
			dialog --title "Raspbmc Updater" --infobox "Updating service management..." 5 50
                # new scripts available for svc management.
                rm /scripts/power.py /scripts/console.py /scripts/xbmc-watchdog.sh /scripts/xbmc_action.py /scripts/xbmcclient.py > /dev/null 2>&1
			wget -q $srcbase/update-system/xbmc-svcmgmt/power.py -O /scripts/power.py
			wget -q $srcbase/update-system/xbmc-svcmgmt/console.py -O /scripts/console.py
			wget -q $srcbase/update-system/xbmc-svcmgmt/xbmc-watchdog.sh -O /scripts/xbmc-watchdog.sh
			wget -q $srcbase/update-system/xbmc-svcmgmt/getlogs.sh -O /scripts/getlogs.sh
			wget -q $srcbase/update-system/xbmc-svcmgmt/autoip.sh -O /scripts/autoip.sh
			wget -q $srcbase/update-system/xbmc-svcmgmt/xinet.sh -O /scripts/xinet.sh
			chmod +x /scripts/*.sh
			wget -q $srcbase/update-system/xbmc-svcmgmt/xbmc_action.py -O /scripts/xbmc_action.py
			wget -q $srcbase/update-system/xbmc-svcmgmt/xbmcclient.py -O /scripts/xbmcclient.py
			wget -q $srcbase/update-system/xbmc-svcmgmt/nm-update-network.py -O /scripts/nm-update-network.py
			chmod +x /scripts/*.py
			wget -q $dlbase/bin/tvheadend.tar.gz
			tar -xzf tvheadend.tar.gz -C / >/dev/null 2>&1
			rm tvheadend.tar.gz >/dev/null 2>&1
			chmod 775 /usr/bin/tvheadend
			pycompile -f /scripts/ > /dev/null 2>&1
			mv svcver /scripts/upd_hist/svcver
                        logger -t update-checker "Updated service management"
			sleep 2 # incase it goes to quick
fi
