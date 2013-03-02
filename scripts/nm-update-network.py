# declare file encoding
# -*- coding: utf-8 -*-

#  Copyright (C) 2012 S7MX1
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with XBMC; see the file COPYING.  If not, write to
#  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#  http://www.gnu.org/copyleft/gpl.html


import sys
import os
import xml.etree.ElementTree as ET
import traceback
import time
import syslog
import signal
from optparse import OptionParser
import logging
import logging.handlers
import pwd

# addon constants
__author__ = "s7mx1"
__addon__ = "script.raspbmc.settings"
DISTRO = "Raspbmc"
try:
    USER = pwd.getpwuid(1000)[0]
except:
    USER = pi
if USER == "pi":
    __addon__ = "script.raspbmc.settings"
    DISTRO = "Raspbmc"
if USER == "atv":
    __addon__ = "script.crystalbuntu.settings"
    DISTRO = "Crystalbuntu"


reload(sys)
sys.setdefaultencoding('utf-8')

def check_service_state(service):
    bus = dbus.SystemBus()
    # Get the manager object
    upstart = bus.get_object("com.ubuntu.Upstart", "/com/ubuntu/Upstart")
    # Lookup the object for the job we're interested in
    # this represents the configuration file on the disk
    path = upstart.GetJobByName(service, dbus_interface="com.ubuntu.Upstart0_6")
    job = bus.get_object("com.ubuntu.Upstart", path)
    # Now lookup the running instance
    # and get its properties
    path = job.GetInstance([], dbus_interface="com.ubuntu.Upstart0_6.Job")
    instance = bus.get_object("com.ubuntu.Upstart", path)
    props = instance.GetAll("com.ubuntu.Upstart0_6.Instance", dbus_interface=dbus.PROPERTIES_IFACE)
    # Print out the goal (start or stop), state (running, etc.) and the list of
    # pids
    return str(props["state"])

def set_logger():
    logger = logging.getLogger('')
    logger.setLevel(logging.DEBUG)

    console = logging.StreamHandler()
    console.setLevel(logging.DEBUG)
    console.setFormatter(logging.Formatter('[%(asctime)s] %(message)s'))


    hdlr=logging.handlers.SysLogHandler(address="/dev/log")
    hdlr.setFormatter(logging.Formatter('[%(asctime)s] %(message)s'))
    hdlr.setLevel(logging.DEBUG)
    logger.addHandler(hdlr)

    logger.addHandler(console)
    return logger


class TimeoutException(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutException()

def default_config():
    nm_dict={'nm.wifi.address': '192.168.1.111', 'nm.search': 'local',  'nm.address': '192.168.1.111', 'nm.wifi.key': '8skgZZhu',
      'nm.wifi.security': '4', 'nm.wifi.5GOnly': 'false', 'nm.wifi.search': 'local', 'nm.dhcp': 'true', 'nm.wifi.netmask': '255.255.255.0',
      'nm.wifi.ssid': DISTRO.lower(), 'nm.wifi.adhoc': 'false', 'nm.netmask': '255.255.255.0', 'nm.wifi.gateway': '192.168.1.1',
      'nm.gateway': '192.168.1.1', 'nm.uid.enable': 'true', 'nm.dns': '192.168.1.1', 'nm.wifi.dhcp': 'true', 'nm.wifi.dns': '8.8.8.8'}
    root= ET.Element("settings")
    for key in nm_dict:
        child = ET.SubElement(root, "setting")
        child.attrib['id'] = key
        child.attrib['value'] = nm_dict[key]
    return root

if ( __name__ == "__main__" ):
    SETTINGS = os.path.join(os.getenv("HOME"),".xbmc","userdata","addon_data",__addon__,"settings.xml")
    ADDON_PATH = os.path.join(os.getenv("HOME"),".xbmc-current","xbmc-bin", "share", "xbmc", "addons", __addon__)
    BASE_RESOURCE_PATH = os.path.join( ADDON_PATH, 'resources', 'lib' )
    DISTRO = "Raspbmc"
    logger = set_logger()
    p = OptionParser()
    p.add_option('--mode', '-m', dest="mode", help="Network Mode: either wired or wireless")
    p.add_option('--ip-address', dest="ip_address", help="Static IP address, e.g. 192.168.1.111")
    p.add_option('--net-mask', dest="net_mask", help="Net mask for  Static IP address, e.g. 255.255.255.0")
    p.add_option('--gate-way', dest="gate_way", help="Gate way for Static IP address, e.g. 192.168.1.1")
    p.add_option('--dns-server', dest="dns_server", help="Name Server for Static IP address, e.g. 8.8.8.8")
    p.add_option('--wifi-disable-dhcp', dest="disable_wifi_dhcp", action="store_true", help ="Set WIFI to Static ip address, default false")
    p.add_option('--wifi-ssid', dest="wifi_ssid", help="WIFI Network SSID, e.g. " + DISTRO.lower())
    p.add_option('--wifi-key', dest="wifi_key", help="WIFI Network Password, e.g. 8skgZZhu")
    p.add_option('--wifi-security', dest="wifi_security", help="WIFI Netowrk Security: one of the following: none, wep-open, wep-shared, dynamic-wep, wpa-1-2")
    p.add_option('--wifi-adhoc', dest="enable_wifi_adhoc", help="WIFI ADHOC Network, default false")
    p.add_option('--wifi-5gonly', dest="enable_wifi_5gonly", help="WIFI 802.11A 5GHz only, default false")
    p.add_option('--do-not-wait', dest="no_wait", help="Do not wait for conenction to come up")

    options, arguments = p.parse_args()
    if options.mode == "wired" or options.mode == "wireless":
        mode = options.mode
    if options.ip_address:
        ip_address = options.ip_address
    if options.net_mask:
        net_mask = options.net_mask
    if options.gate_way:
        gate_way = options.gate_way
    if options.dns_server:
        dns_server = options.dns_server
    if options.wifi_ssid:
        wifi_ssid = options.wifi_ssid
    if options.wifi_key:
        wifi_key = options.wifi_key
    if options.wifi_security:
        wifi_security = options.wifi_security
    if options.disable_wifi_dhcp:
        disable_wifi_dhcp = options.disable_wifi_dhcp
    if options.enable_wifi_adhoc:
        enable_wifi_adhoc = options.enable_wifi_adhoc
    if options.enable_wifi_5gonly:
        enable_wifi_5gonly = options.enable_wifi_5gonly
    if options.no_wait:
        no_wait = options.no_wait

    if "mode" in locals():
        update_dict={}
        if os.path.isfile(SETTINGS):
            tree = ET.parse(SETTINGS)
            root = tree.getroot()
        else:
            root = default_config()
            tree = ET.ElementTree(root)

        if mode == "wired":
            update_dict["nm.dhcp"] = "false"

        if "ip_address" in locals():
            if mode == "wired":
                update_dict["nm.address"] = ip_address
            if mode == "wireless":
                update_dict["nm.wifi.address"] = ip_address
        if "net_mask" in locals():
            if mode == "wired":
                update_dict["nm.netmak"] = net_mask
            if mode == "wireless":
                update_dict["nm.wifi.netmak"] = net_mask
        if "gate_way" in locals():
            if mode == "wired":
                update_dict["nm.gateway"] = gate_way
            if mode == "wireless":
                update_dict["nm.wifi.gateway"] = gate_way
        if "dns_server" in locals():
            if mode == "wired":
                update_dict["nm.dns"] = dns_server
            if mode == "wireless":
                update_dict["nm.wifi.dns"] = dns_server
        if "wifi_ssid" in locals():
            update_dict["nm.wifi.ssid"] = wifi_ssid
        if "wifi_key" in locals():
            update_dict["nm.wifi.key"] = wifi_key
        if "wifi_security" in locals():
            if wifi_security == "none":
                update_dict["nm.wifi.security"] = "0"
            if wifi_security == "wep-open":
                update_dict["nm.wifi.security"] = "1"
            if wifi_security == "wep-shared":
                update_dict["nm.wifi.security"] = "2"
            if wifi_security == "dynamic-wep":
                update_dict["nm.wifi.security"] = "3"
            if wifi_security == "wpa-1-2":
                update_dict["nm.wifi.security"] = "4"
        if "disable_wifi_dhcp" in locals():
            update_dict["nm.wifi.dhcp"] = "false"
        if "enable_wifi_adhoc" in locals():
            update_dict["nm.wifi.adhoc"] = "true"
        if "enable_wifi_5gonly" in locals():
            update_dict["nm.wifi.adhoc"] = "true"

        for child in root:
            for key in update_dict:
                if child.attrib['id'] == key:
                    child.attrib['value'] = update_dict[key]

        tree.write(SETTINGS)


    if os.path.isdir(BASE_RESOURCE_PATH):
        sys.path.append (BASE_RESOURCE_PATH)
    if os.path.isdir("/scripts"):
        sys.path.append ("/scripts")
    nm_dict={}
    sys_dict={}
    if os.path.isfile(SETTINGS):
        tree = ET.parse(SETTINGS)
        root = tree.getroot()
    else:
        root = default_config()
    if "root" in locals():
        for child in root:
            if child.attrib['id'].startswith("nm."):
                nm_dict[child.attrib['id']]=child.attrib['value']
            if child.attrib['id'].startswith("sys.") or child.attrib['id'].startswith("remote."):
                sys_dict[child.attrib['id']]=child.attrib['value']
    if len(sys_dict) >0:
        from switches import *
        RESTART_ACTION,RESTART_MESSAGE,REBOOT_ACTION,REBOOT_MESSAGE = set_switch(sys_dict,DISTRO)
        for line in RESTART_MESSAGE:
            syslog.syslog(line)
        for line in REBOOT_MESSAGE:
            syslog.syslog(line)
            import dbus
            try:
                if "repeat filter" in line or "Remote configuration" in line:
                    if os.path.isfile("/sbin/initctl"):
                        if check_service_state("eventlircd") == "running":
                            os.system("sudo initctl stop eventlircd")
                            os.system("sudo initctl start eventlircd")
                    break
            except dbus.exceptions.DBusException:
                break
            except:
                exc_type, exc_value, exc_traceback = sys.exc_info()
                lines = traceback.format_exception(exc_type, exc_value, exc_traceback)
                logger.debug(''.join('!! ' + line for line in lines))

    if len(nm_dict ) >0:
        from nm_util import *
        try:
            nm = NetworkManager()
            CONFIG_IP_RESET = False
            for conn in nm.connections:
                for interface in nm.devices:
                    if str(conn.settings.mac_address) == str(interface.hwaddress):
                        conn_state=int(interface.proxy.Get(NM_DEVICE, "State"))
                        index=0
                        while conn_state == 70 or conn_state == 80:
                            if index >=12:
                                CONFIG_IP_RESET = True
                                break
                            logger.debug("Wait 5 seconds for Network Interface %s %s to configure IP Address" % (str(conn),str(conn.settings.mac_address)))
                            time.sleep(5)
                            index += 1
                            conn_state=int(interface.proxy.Get(NM_DEVICE, "State"))

            re_code=modify_connection(nm_dict,nm)
            if re_code == -11:
                logger.debug("network settings from"+DISTRO+ "addon: "+str(nm_dict))
                conn_state = None
                for conn in nm.connections:
                    for interface in nm.devices:
                        if str(conn.settings.mac_address) == str(interface.hwaddress):
                            conn_state=int(interface.proxy.Get(NM_DEVICE, "State"))
                            logger.debug("[%s] device state: %s" % (str(conn),str(conn_state)))
                            if conn_state == 100:
                                logger.debug("[%s] device address: %s" % (str(conn),str(interface.ip4config.addresses[0][0])))
                                logger.debug("[%s] device netmask: %s" % (str(conn),str(interface.ip4config.addresses[0][1])))
                                logger.debug("[%s] device gateway: %s" % (str(conn),str(interface.ip4config.addresses[0][2])))
                                logger.debug("[%s] device dns: %s" % (str(conn),str(interface.ip4config.name_servers[0])))
                            break
                    for key in ("auto","address","conn_type","dhcp_client_id","dns","dns_search","duplex","gateway","id","mac_address","netmask","type","uuid"):
                        if hasattr(conn.settings,key):
                            exec "var_string=conn.settings.%s" % key
                            logger.debug("[%s] connection property %s: %s" %(str(conn),key,str(var_string)))
            elif re_code == 10:
                # notify
                #xbmc.executebuiltin('XBMC.Notification("'+"Network Configuration Applied"+'",,1500,"'+'")')
                if CONFIG_IP_RESET:
                    nm.proxy.Enable(dbus.Boolean(0))
                    nm.proxy.Enable(dbus.Boolean(1))
                pass
            elif re_code == 0:
                ## no change
                pass
            ## force enable network manger in case the state file indicates something different
            try:
                nm.proxy.Enable(dbus.Boolean(1))
            except:
                pass
            if not "no_wait" in locals():
                DEV_ACTIVATED = False
                type2desc = {1:'802-3-ethernet', 2:'802-11-wireless'}
                signal.signal(signal.SIGALRM, timeout_handler)
                signal.alarm(120) # triger alarm in 60 seconds
                while not DEV_ACTIVATED:
                    try:
                        for interface in nm.devices:
                            dev_state=interface.proxy.Get(NM_DEVICE, "State")
                            dev_type_int = interface.proxy.Get(NM_DEVICE, "DeviceType")
                            dev_type = type2desc.get(dev_type_int, None)
                            if dev_state == 100: # NM_DEVICE_STATE_ACTIVATED
                                DEV_ACTIVATED = True

                                logger.debug("Valid Network Interface found and Activated")
                                logger.debug("MAC: %s, Type: %s" % ( interface.hwaddress, dev_type))
                                logger.debug("IP Address:  %s, Netmask: %s " % ( interface.ip4config.addresses[0][0],
                                                   interface.ip4config.addresses[0][1]) )
                                logger.debug("Gateway: %s, DNS: %s" % (interface.ip4config.addresses[0][2], interface.ip4config.name_servers[0]))
                        if not DEV_ACTIVATED:
                            logger.debug("Wait 8 seconds for Network Interface to come up")
                            time.sleep(8)
                    except TimeoutException:
                        logger.debug("Giving up waiting for Network Interface")
                        break

        except:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            lines = traceback.format_exception(exc_type, exc_value, exc_traceback)
            logger.debug(''.join('!! ' + line for line in lines))

