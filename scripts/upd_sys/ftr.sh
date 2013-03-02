#!/bin/bash
dialog --title "Raspbmc Installer" --infobox "Setting up Raspbmc for first run..." 5 50
mkswap /dev/mmcblk0p2 > /dev/null 2>&1
swapon /dev/mmcblk0p2 > /dev/null 2>&1
#dpkg-reconfigure winbind > /dev/null 2>&1
rm /etc/dropbear/*host_key > /dev/null 2>&1
dropbearkey -f /etc/dropbear/dropbear_rsa_host_key -t rsa > /dev/null 2>&1
dropbearkey -f /etc/dropbear/dropbear_dss_host_key -t dss > /dev/null 2>&1
dbus-uuidgen --ensure > /dev/null 2>&1
depmod
touch /scripts/upd_hist/ftr-configured
reboot
sleep 999

