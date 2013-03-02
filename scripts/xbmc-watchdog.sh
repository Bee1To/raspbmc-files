#!/bin/bash
FBSET="/bin/fbset"
if [ -e $FBSET ]; then
    if [ ! -f /tmp/fb_resolution ]; then
      FB_RESOLUTION=$(fbset | grep geometry | awk '{print "-xres "$2" -yres "$3" -vxres "$4" -vyres "$5}')
      echo $FB_RESOLUTION > /tmp/fb_resolution
    fi
fi
while true
do
    # detach fb to save gpu memory
    if [ -e $FBSET ]; then
      echo 0 >  /sys/class/vtconsole/vtcon1/bind
      fbset -xres 1 -yres 1 -vxres 1 -vyres 1
    else
      chvt 1
      set +v
      tput civis
      tput setf 0
      start --no-wait splash
    clear
    fi
    if [ ! -h /home/pi/.xbmc-current ]; then
        if [ -e /home/pi/.xbmc-current ]; then
            rm -rf /home/pi/.xbmc-current
        fi
        su - pi -c "ln -s /opt/xbmc-bcm /home/pi/.xbmc-current"
        ldconfig
    fi
    if [ -f /etc/ld.so.cache ]; then
      xbmc_libs=$(grep .xbmc-current /etc/ld.so.cache)
    else
      xbmc_libs=""
    fi
    if [ ! -f /boot/config.txt ]; then
    # treat Raspbmc Settings nicely
    touch /boot/config.txt
    fi
    test "x$xbmc_libs" != "x" || ldconfig
    setcap cap_net_admin,cap_net_bind_service,cap_net_raw=ep /home/pi/.xbmc-current/xbmc-bin/lib/xbmc/xbmc.bin
    date -u +%s > /var/run/splash-timestamp  
    if [ -f /usr/lib/libcofi_rpi.so ]; then
    	su - pi -c "export XBMC_HOME=$(readlink /home/pi/.xbmc-current)'/xbmc-bin/share/xbmc' ; LD_PRELOAD=/usr/lib/libcofi_rpi.so /home/pi/.xbmc-current/xbmc-bin/lib/xbmc/xbmc.bin --standalone -fs --lircdev /var/run/lirc/lircd 2>&1 | logger -t xbmc"
    else
	su - pi -c "export XBMC_HOME=$(readlink /home/pi/.xbmc-current)'/xbmc-bin/share/xbmc' ; /home/pi/.xbmc-current/xbmc-bin/lib/xbmc/xbmc.bin --standalone -fs --lircdev /var/run/lirc/lircd 2>&1 | logger -t xbmc"
    fi
    last_execute_time=$(cat /var/run/splash-timestamp)
    current_time=$(date -u +%s)
    time_diff=$(($current_time - $last_execute_time))
    #TO DO: xbmc-troubleshooting.py script
    #test "$time_diff" -le 30 || /scripts/xbmc-troubleshooting.py
case "$?" in
        0) # user quit. Wait for 60s grace period so user can login into console tty*
            # reattach fb
            if [ -e $FBSET ]; then
              if [ -f /tmp/fb_resolution ]; then
                fbset `cat /tmp/fb_resolution`
              fi
              echo 1 >  /sys/class/vtconsole/vtcon1/bind
              DEPTH2=$(fbset | head -3 | tail -1 | cut -d " " -f 10)
              if [ "$DEPTH2" = "8" ]; then
                DEPTH1=16
              elif [ "$DEPTH2" = "16" ]; then
                DEPTH1=8
              elif [ "$DEPTH2" = "32" ]; then
                DEPTH1=8
              else
                DEPTH1=8
                DEPTH2=16
              fi
              fbset -depth $DEPTH1 && fbset -depth $DEPTH2
              start console-setup
              echo -e "\033c" > /dev/tty1
            fi
            dialog --title "Raspbmc" --infobox "Relax, XBMC will restart shortly.\n\nPress ESC key for a command line" 0 0 > /dev/tty1
            read -sn 1 -t 10 press < /dev/tty1
            if [ "$press" = $'\e' ]; then
                    # user pressed escape. now switching to 2nd terminal
                    chvt 2
                    set -v
                    tput cnorm
                    tput setf 7
                    sleep 55
                    while true
                    do
                        login_check=$(who | awk '{print $2}' | grep ^tty[0-9])
                        if [ "$login_check" = "" ]; then
                            break
                        fi
                        sleep 5
                    done
            else
                    # no user input. resume xbmc
                    sleep 2
            fi;;
        64) # shutdown system.
            set -v
            tput cnorm
            tput setf 7
            sleep 60 ;;
        65) # warm Restart xbmc
            sleep 2 ;;
        66) # Reboot System
            set -v
            tput cnorm
            tput setf 7
            sleep 60 ;;
        *)  # this should not happen
            set -v
            tput cnorm
            tput setf 7
            sleep 30 ;;
            
    esac
done
