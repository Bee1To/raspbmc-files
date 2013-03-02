# run ftr
tty=$(tty)
if [ "$tty" = "not a tty" ]
then
tty=/dev/tty1
fi
if [ -f /home/pi/.configureduser ] || [ "$tty" = "/dev/tty1" ]
then
  # already setup this user OR we are on the xbmc tty
  /bin/true
else
clear
echo 'Hi there! You have logged into your Pi for the first time'
echo 'Allow me to set up your timezone and keyboard settings'
echo 'Please wait a few seconds...'
sudo dpkg-reconfigure locales
sudo dpkg-reconfigure tzdata
clear
echo 'All set up now! Thanks for using Raspbmc.'
echo 'And may I kindly advise you to read the Wiki if you have issues'
echo 'Note, you still need to configure your locales in XBMC'
# Putting it here means if they dont complete it, we will keep prompting
touch /home/pi/.configureduser
fi

