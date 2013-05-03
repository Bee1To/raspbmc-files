#!/bin/bash

# Apply update
dialog --title "Raspbmc Updater" --infobox "Patching root filesystem" 5 50
logger -t update-checker "Need to patch rootfs with 041322"
servs="xinetd
udev
dbus
cron
xbmc
console-setup
avahi-daemon
winbind"
for service in $servs
do
update-rc.d $service remove -f
rm /etc/init.d/$service
done
wget http://svn.stmlabs.com/svn/raspbmc/testing/oscore/upstart-wheezy/thresh.conf -O /etc/init/thresh.conf
echo "raspbmc-rls-1.0-hardfp-b20130208-u20130422" > /scripts/upd_hist/build_info
# Mark as installed
touch /scripts/upd_hist/.041322
reboot
sleep 9999
