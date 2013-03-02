#!/usr/bin/python
import os
import sys

XBOX="lirc_xbox"
list=[[(0x040b,0x6521),XBOX],[(0x045e,0x0284),XBOX]]

def lirc_workaround(action):
    import usb.core
    import usb.util
    devs = usb.core.find(find_all=1)
    for dev in devs:
        for id,driver in list:
            if (dev.idVendor,dev.idProduct) == id:
                if action == "Quit" or action == "Powerdown" or action == "Reboot" or action == "ShutDown":
                    os.system('sudo rmmod '+driver)
                if action == "Start":
                    os.system('sudo modprobe '+driver)
    
    if action == "Quit" or action == "Powerdown" or action == "Reboot" or action == "ShutDown":
        import xbmc
        xbmc.executebuiltin(action)

if len(sys.argv) > 1:
    if sys.argv[1] == "start":
        lirc_workaround("Start")

