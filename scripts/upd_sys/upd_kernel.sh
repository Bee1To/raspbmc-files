#!/bin/bash
kernelstub="latest-hardfp.tar.gz"
rm kver > /dev/null 2>&1
wget -q $srcbase/update-system/kernel/kver
if [ "$?" -ne 0 ]
then
	logger -t update-checker "Could not get kver diff file"
        exit 1

fi
if diff kver /scripts/upd_hist/kver >/dev/null ; then
  logger -t update-checker "Kernel is up-to-date"
else
           chvt 1
           clear
           initctl stop xbmc
           # kernel update available. let's get it.
                logger -t update-checker "Downloading kernel binaries"
		dlprogress "$dlbase/bin/kernel/kernel-vfat-$kernelstub" "Downloading kernel binaries" "1"
		if [ "$?" -ne 0 ]
		then
		  exit 1
                fi
                logger -t update-checker "Downloading kernel modules and libraries"
		dlprogress "$dlbase/bin/kernel/kernel-rootfs-$kernelstub" "Downloading kernel modules" "1"
		if [ "$?" -ne 0 ]
                then
                  exit 1
                fi
		logger -t update-checker "Downloading kernel headers"
		dlprogress "$dlbase/bin/kernel/linux-headers-latest.deb.gz" "Downloading kernel headers" "1"
		if ["$?" -ne 0 ]
		then
		 exit 1
		fi
		rm -rf /lib/modules/* > /dev/null 2>&1
		rm -rf /usr/src/* > /dev/null 2>&1
		verifiedextraction "kernel-vfat-$kernelstub" "/boot" "Extracting kernel binaries"
		verifiedextraction "kernel-rootfs-$kernelstub" "/" "Extracting kernel modules"
		logger -t update-checker "Installing kernel headers"
		mv linux-headers-latest.deb.gz linux-headers-latest.deb > /dev/null 2>&1
		dpkg -i linux-headers-latest.deb > /dev/null 2>&1
		rm kernel-rootfs-$kernelstub > /dev/null 2>&1
		rm kernel-vfat-$kernelstub > /dev/null 2>&1
		rm linux-headers-latest.deb >/dev/null 2>&1
		rm $(echo kernel-rootfs-${kernelstub} | sed -e 's/.\{6\}$//' -e 's/$/md5/') > /dev/null 2>&1
		rm $(echo kernel-vfat-${kernelstub} | sed -e 's/.\{6\}$//' -e 's/$/md5/') > /dev/null 2>&1
		rm linux-headers-latest.md5 > /dev/null 2>&1
		if [ -f /scripts/upd_sys/.USB ]
		then
                for line in `cat /proc/cmdline`; do
                    root=$(echo $line | grep "root=" | sed -e "s/root=//")
                    if [ "x$root" != "x" ]; then
                    root_dev=$(basename $root)
                    fi
                done
                fi
                if [ -f /scripts/upd_sys/.NFS ]; then
                for line in `cat /proc/cmdline`; do
                    root=$(echo $line | grep "nfsroot=" | sed -e 's/\//\\\//g')
                    SETTINGS=/home/pi/.xbmc/userdata/addon_data/script.raspbmc.settings/settings.xml
                    DHCP=$(grep nm.dhcp $SETTINGS | awk '{print $3}'  | cut -f2 -d "=" | sed -e "s/\"//g")
                    if  [ "$DHCP" == "false" ]; then
                        address=$(grep nm.address $SETTINGS | awk '{print $3}'  | cut -f2 -d "=" | sed -e "s/\"//g" |  sed -e "s/\'//g")
                        netmask=$(grep nm.netmask $SETTINGS | awk '{print $3}'  | cut -f2 -d "=" | sed -e "s/\"//g"  |  sed -e "s/\'//g")
                        gateway=$(grep nm.gateway $SETTINGS | awk '{print $3}'  | cut -f2 -d "=" | sed -e "s/\"//g"  |  sed -e "s/\'//g")
                        IP_CONFIG="$address""::""$gateway"":""$netmask"":raspbmc:eth0:off"
                    else
                        IP_CONFIG="dhcp"
                    fi
                    if [ "x$root" != "x" ]; then
                    root_dev="nfs ip=$IP_CONFIG $root,v3"
                    sed -e "s/ext4/nfs/" -i /boot/cmdline.txt
                    fi
                done
                fi
                if [ "x$root_dev" != "x" ]; then 
		  if ! grep mmcblk0p3 /etc/fstab; then sed -e "s/mmcblk0p2/${root_dev}/" -i /boot/cmdline.txt; else sed -e "s/mmcblk0p3/${root_dev}/" -i /boot/cmdline.txt; fi
                fi
		if ! grep gpu_mem /boot/config.txt; then echo "gpu_mem=128" >>/boot/config.txt; fi
		# complete
		ldconfig
		depmod
		mv kver /scripts/upd_hist/kver
                logger -t update-checker "Updated kernel binaries/modules and system libraries. Rebooting"
		# reboot kernel
		reboot
		sleep 999
fi

