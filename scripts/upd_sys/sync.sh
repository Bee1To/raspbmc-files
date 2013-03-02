#!/bin/bash

# Run quiet?
QUIET=1

# disable screensaver
setterm -blank 0

if [ ${QUIET} -eq 0 ]
then
    QUIET=""
else
    QUIET="-q"
fi

updatefile ()
{
    local url=$1
    local file=`echo -n "${url}" | sed 's/.*\///g'`

    # HACK because wget returns 0 when it shouldn't
    if [ "$(echo "${url}" | sed 's/^http//')" = "${url}" ]
    then
    	# i.e. we can't parse http from the start of the URL
	return 1
    fi
    
    mv "${file}" "${file}.bak" 2>/dev/null
    wget "${QUIET}" "${url}"  
    if [ $? -ne 0 ]
    then
        mv "${file}.bak" "${file}" 2>/dev/null
        return 1
    else
        rm "${file}.bak" 2>/dev/null
        return 0
    fi
}

# configure cdn
logger -t update-checker "Downloading cdn_env_prep.sh"
updatefile http://svn.stmlabs.com/svn/raspbmc/testing/update-system/cdn_env_prep.sh
if [ $? -ne 0 ]
then
    echo "Update failed - cdn_env_prep.sh" >&2
    logger -t sync.sh "Update failed - cdn_env_prep.sh"
    sleep 5
    exit 1
fi

chmod +x cdn_env_prep.sh
source ./cdn_env_prep.sh

FAILED=0
logger -t update-checker "Downloading getfile.sh"
updatefile $srcbase/update-system/getfile.sh
if [ $? -ne 0 ]
then
    FAILED=1
fi
logger -t update-checker "Downloading upd_kernel.sh"
updatefile $srcbase/update-system/kernel/upd_kernel.sh
if [ $? -ne 0 ]
then
    FAILED=1
fi
logger -t update-checker "Downloading upd_xbmc.sh"
updatefile $srcbase/update-system/xbmc/upd_xbmc.sh
if [ $? -ne 0 ]
then
    FAILED=1
fi
logger -t update-checker "Downloading upd_xbmc_svc.sh"
updatefile $srcbase/update-system/xbmc-svcmgmt/upd_xbmc_svc.sh
if [ $? -ne 0 ]
then
    FAILED=1
fi
logger -t update-checker "Downloading upd_sys.sh"
updatefile $srcbase/update-system/system/upd_sys.sh
if [ $? -ne 0 ]
then
    FAILED=1
fi

# Die if any above commands failed
if [ "${FAILED}" -ne 0 ]
then
    echo "Update failed - wget" >&2
    logger -t sync.sh "Update failed - wget"
    sleep 5
    exit 2
fi

## make sure previous downloads are cleared out
rm -rf *.md5* > /dev/null 2>&1
rm -rf *.tar.gz* > /dev/null 2>&1

chmod +x getfile.sh upd_xbmc.sh upd_kernel.sh upd_sys.sh upd_xbmc_svc.sh cdn_env_prep.sh
# update kernel
. ./upd_kernel.sh
## update system
. ./upd_sys.sh
## update xbmc-related scripts
. ./upd_xbmc_svc.sh
## update xbmc
. ./upd_xbmc.sh
initctl start xbmc > /dev/null 2>&1
