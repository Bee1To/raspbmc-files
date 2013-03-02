#!/bin/bash
cd /home/pi
cat /scripts/upd_hist/build_info
echo "Please be patient -- the uploading of logs can take some time"
{
echo "SYSLOG"
echo "" 
cat /var/log/syslog 
echo "" 
echo "LATEST XBMC LOG" 
echo "" 
cat /home/pi/.xbmc/temp/xbmc.log 
echo "" 
echo "UPDATE HISTORY" 
echo ""  
ls -l /scripts/upd_hist 
echo "" 
echo "SYSTEM INFORMATION" 
echo "" 
df -h 
free -m 
}>LOG
split --bytes=2M LOG logs
url="" # reset
for log in $(ls logs*)
do
 url="${url} $(echo -e '\n') $(pastebinit -i $log -b http://pastebin.com)"
done
url=$(echo -e "$url" | pastebinit -b http://pastebin.com)
rm LOG logs*
echo "Please visit $url which contains the Pastebin links to the logs. Note this may span multiple logs if the files exceed Pastebin's upload size."
