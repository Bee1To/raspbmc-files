#!/bin/bash
latestxbmc="xbmc-rbp-20130222.tar.gz"
rm xbmcver > /dev/null 2>&1
wget -q $srcbase/update-system/xbmc/xbmcver
if [ "$?" -ne 0 ]
then
        logger -t update-checker "Could not get xbmc diff file"  
        exit 1
fi
if diff xbmcver /scripts/upd_hist/xbmcver >/dev/null ; then
  logger -t update-checker "XBMC is up to date"
else
                chvt 1
                clear
                initctl stop xbmc
                # xbmc update available. let's get it.
			logger -t update-checker "Downloading XBMC"
			dlprogress "$dlbase/bin/xbmc/$latestxbmc" "Downloading new XBMC build" "1"
			if [ "$?" -ne 0 ]
			then
			 exit 1
			fi
			rm -rf /opt/xbmc-bcm >/dev/null 2>&1
			logger -t update-checker "Installing XBMC"
			verifiedextraction "$latestxbmc" "/opt" "Extracting XBMC"
			rm $latestxbmc >/dev/null 2>&1
			rm $(echo ${latestxbmc} | sed -e 's/.\{6\}$//' -e 's/$/md5/') >/dev/null 2>&1
			# complete
                        pycompile -f /opt/xbmc-bcm/xbmc-bin/share/xbmc/addons/
                        if [ ! -f /etc/ld.so.conf.d/xbmc.conf ]; then
                          echo /home/pi/.xbmc-current/xbmc-bin/lib/xbmc/system > /etc/ld.so.conf.d/xbmc.conf
                        fi
			ldconfig
			mv xbmcver /scripts/upd_hist/xbmcver
			logger -t update-checker "Updated XBMC"
fi
