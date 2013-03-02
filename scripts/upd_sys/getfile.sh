#!/bin/bash
#this lets us change the synchronisation script location if ever necessary. allowing differentiation between versions.

wget --timeout=20 --spider svn.stmlabs.com > /dev/null 2>&1
if [ "$?" -eq 0 ]
then
    cd /scripts/upd_sys
    if [ ! -f /home/pi/.noupgrades ]; then
        mv sync.sh sync.sh.bak 2>/dev/null
        wget -q "http://svn.stmlabs.com/svn/raspbmc/testing/update-system/sync.sh"
        if [ "$?" -ne 0 ]
        then
            mv sync.sh.bak sync.sh
            exit 1
        fi

        rm sync.sh.bak 2>/dev/null
        chmod +x sync.sh
        ./sync.sh
        exit 0
    fi
else
    logger -t update-checker "Unable to connect to Raspbmc SVN server. Skipping updates"
fi

