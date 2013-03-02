#!/usr/bin/python

# This is a simple example showing how you can send a key press event
# to XBMC using the XBMCClient class

import sys
sys.path.append("/scripts")

from xbmcclient import XBMCClient,ACTION_EXECBUILTIN,ACTION_BUTTON

def main():

    host = "localhost"
    port = 9777
    
    if sys.argv[1] == "LIRC.Start": 
    # Create an XBMCClient object and connect
        xbmc = XBMCClient("Starting LIRC")
    if sys.argv[1] == "LIRC.Stop":
        xbmc = XBMCClient("Stopping LIRC")
    xbmc.connect()

    try:
        xbmc.send_action(sys.argv[1], ACTION_EXECBUILTIN)
    except Exception, e:
        print str(e)
        xbmc.send_action("XBMC.ActivateWindow(ShutdownMenu)")
    

    # ok we're done, close the connection
    # Note that closing the connection clears any repeat key that is
    # active. So in this example, the actual release button event above
    # need not have been sent.
    xbmc.close()

if __name__=="__main__":
    main()
