#!/bin/bash
# let's find one mirror and stick to it or else there
# is a chance of synchronisation mismatch!

server=$(env LANG=C wget -S --spider --timeout 60 http://download.raspbmc.com 2>&1 > /dev/null | grep "^Location:" | cut -f 2 -d ' ')
export server

branch=testing
export branch

dlbase="${server}/downloads"
export dlbase

srcbase="http://svn.stmlabs.com/svn/raspbmc/$branch"
export srcbase

# functions used by update system

logging() {
if [ -f /usr/bin/logger ]; then
  logger -t "$1" "$2"
else
echo "$2" >> /tmp/"$1".log
fi
}

dlprogress() {
rm "${1}" | sed 's/.*\///' > /dev/null 2>&1
logging update-checker "Downloading ${1}"
wget "${1}" 2>&1 | grep --line-buffered -o "[0-9]\{1,3\}%" | grep --line-buffered -o "[0-9]\{1,3\}" | dialog --title "Raspbmc Updater" --guage "${2}" 10 60
if [ "$#" -eq 3 ] && [ "$?" -eq 0 ]
then
   logging update-checker "${1} successfully downloaded"
   logging update-checker "Downloaidng md5sum for ${1}"
  # pull md5 too
  wget -q $(echo $1 | sed -e 's/.\{6\}$//' -e 's/$/md5/')
  if [ "$?" -eq 0 ]
  then
      logging update-checker "Md5sum for ${1} successfully downloaded"
  else
      logging update-checker "Couldn't fetch md5sum for ${1}"
      return 1
  fi
else
logging update-checker "Couldn't fetch ${1}"
return 1
fi
}

dlnoprogress() {
rm "${1}" | sed 's/.*\///' > /dev/null 2>&1
logging update-checker "Downloading ${1}"
wget -q ${1} -O ${2}
if [ "$?" -ne 0 ]
then
  logging update-checker "Couldn't fetch ${1}"
  return 1
fi
}

verifiedextraction() {
# check MD5 integrity
logging update-checker "Verify hash of ${1} when ${3}"

tr -d "\r" < $(echo $1 | sed -e 's/.\{6\}$//' -e 's/$/md5/') | md5sum --check

if [ "$?" -eq 0 ]
then
   logging update-checker "${1} verified successfully"
   mkdir -p /scripts/backup
   CURRENT_PWD=$(pwd)
   cd "$2"
   echo "$2" > /scripts/backup/"$1".dir
   tar -tzf $1 > /scripts/backup/"$1".tarfilelist
   if [ -f /scripts/backup/"$1".filelist ]; then
     rm /scripts/backup/"$1".filelist
   fi
   if [ -f /scripts/backup/"$1".nofilelist ]; then
     rm /scripts/backup/"$1".nofilelist
   fi
   for file in `cat /scripts/backup/"$1".tarfilelist` ; do
     if [ -f "$file" ]; then
       echo "$file" >> /scripts/backup/"$1".filelist
     elif [ ! -d "$file" ]; then
       echo "$file" >> /scripts/backup/"$1".nofilelist
     fi
   done
   
   tar -czf /scripts/backup/$1 `cat /scripts/backup/"$1".filelist`
   cd $CURRENT_PWD
  { pv -n "$1" | { if [ ! -z "$2" ]; then mkdir -p "$2"; fi && cd "$2" && tar -xzf -; } 2>/dev/null; } 2>&1 | dialog --title "Raspbmc Updater" --gauge "$3" 6 50
   if [ "$?" -eq 0 ]
   then
       logging update-checker "${1} extracted successfully"
   else
       logging update-checker "Couldn't extract ${1}"
       return 1
   fi
else
   logging update-checker "Couldn't verify hash of ${1} when ${3}"
   return 1
fi
}
export logging
export verifiedextraction
export dlprogress
export dlnoprogress
