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

import os
import sys
import uuid

def convert_entry(entry):
    return entry.split("=")[1].strip()

if os.path.isfile("/var/log/dmesg"):
    f=open("/var/log/dmesg",'r')
    for line in f.readlines():
        if "device=" in line:
            device, address, netmask, gateway = line.split(",")
        if "host=" in line:
            host,domain,nis_domain = line.split(",")
    f.close()
    nm={"nm.dns":"8.8.8.8","nm.dhcp":"false"}
    for key in ("device", "address", "netmask", "gateway", "host","domain"):
        if key in ("address", "netmask", "gateway"):
            nm["nm."+key]=convert_entry(locals()[key])
        else:
            nm[key]=convert_entry(locals()[key])

nm_conf_folder="/etc/NetworkManager/system-connections"
nm_conf_file_dict=[]
for file in os.listdir(nm_conf_folder):
    if file.startswith("Wired"):
        nm_conf_file_dict.append(file)

FORCE_NM_CONFIG=True

current_mac=':'.join(['{:02x}'.format((uuid.getnode() >> i) & 0xff) for i in range(0,8*6,8)][::-1])
os.environ["MATCHADDR"]=current_mac
os.environ["MATCHDRV"]="smsc95xx"

if len(nm_conf_file_dict)>0:
    for file in nm_conf_file_dict:
        nm_conf = os.path.join(nm_conf_folder,file)
        if os.path.isfile(nm_conf):
            f=open(nm_conf,'r')
            for line in f.readlines():
                if "mac-address=" in line:
                    mac=line.split("=")[1].strip()
                    if current_mac.lower() == mac.lower():
                        FORCE_NM_CONFIG=False
                        break
            f.close()

if len(nm_conf_file_dict) == 0 or FORCE_NM_CONFIG:
    os.system("test 'x$MATCHDRV' != 'x' || export MATCHDRV='smsc95xx'; test 'x$MATCHADDR' != 'x' || export MATCHADDR=$(ifconfig | grep eth0 | awk '{print $5}'); export UUID=$(cat /proc/sys/kernel/random/uuid); test 'x$UUID' != 'x' || export UUID=11111111-1111-1111-1111-111111111111; export ROOT='/etc/NetworkManager/system-connections'; bash -c \". /lib/udev/write_nm_config; create_wired_conf '$MATCHADDR' '$UUID' '$ROOT'\"")

    for file in os.listdir(nm_conf_folder):
        if file.startswith("Wired"):
            nm_conf_file_dict.append(file)

dhcp_lease="/var/lib/dhcp/dhclient"
for file in nm_conf_file_dict:
    nm_conf = os.path.join(nm_conf_folder,file)
    if os.path.isfile(nm_conf):
        VALID_CONFIG = False
        DHCP_IP=True
        f=open("/proc/cmdline",'r')
        for line in f.readlines():
            if "ip=" in line:
                if not "ip=dhcp" in line:
                    DHCP_IP=False
                    break
        f.close()

        f=open(nm_conf,'r')
        for line in f.readlines():
            if "mac-address=" in line:
                mac=line.split("=")[1].strip()
                if current_mac.lower() == mac.lower():
                    VALID_CONFIG = True
                    break
        f.close()
        if VALID_CONFIG:
            if not DHCP_IP:
                import xml.etree.ElementTree as ET
                import StringIO
                import ConfigParser
                SETTINGS = os.path.join("/home/pi",".xbmc","userdata","addon_data","script.raspbmc.settings","settings.xml")
                if os.path.isfile(SETTINGS):
                    tree = ET.parse(SETTINGS)
                    root = tree.getroot()
                    DICT_UPDATE=False
                    for child in root:
                        for key in nm:
                            if child.attrib['id'] == key:
                                if key != "nm.dns":
                                    if child.attrib['value'] != nm[key]:
                                        child.attrib['value'] = nm[key]
                                        DICT_UPDATE=True
                                else:
                                    nm[key] = child.attrib['value']
                    if DICT_UPDATE:
                        tree.write(SETTINGS)
                        os.system("chown pi:pi "+SETTINGS)
                binary_str = ''
                for octet in nm["nm.netmask"].split('.'):
                    binary_str += bin(int(octet))[2:].zfill(8)
                cidr=str(len(binary_str.rstrip('0')))
                static_ip_string=nm["nm.address"]+";"+cidr+";"+nm["nm.gateway"]+";"
                config = ConfigParser.ConfigParser()
                config.optionxform = str
                config.read(nm_conf)
                config.set('ipv4','method','manual')
                config.set('ipv4','addresses1',static_ip_string)
                config.set('ipv4','dns',nm["nm.dns"])
                ini_str = ""
                ini_fp = StringIO.StringIO(ini_str)
                config.write(ini_fp)
                ini_fp.seek(0)
                f = open(nm_conf,'w')
                for line in ini_fp.readlines():
                    f.write(line.replace(" = ","="))
                f.close()
                escape_nm_conf=nm_conf.replace(" ","\\ ")
                os.system("chmod 600 "+escape_nm_conf)

            else:
                    f=open(nm_conf,'r')
                    for line in f.readlines():
                        if "uuid=" in line:
                            uuid=line.split("=")[1].strip()
                            break
                    f.close()
                    dhcp_lease=os.path.join("/var/lib/dhcp/","dhclient-"+uuid+"-"+nm["device"]+".lease")
                    f=open(dhcp_lease,'w')
                    f.write("lease {\n")
                    f.write("  interface \"%s\";\n" % nm["device"])
                    f.write("  fixed-address %s;\n" % nm["nm.address"])
                    f.write("  option subnet-mask %s;\n" % nm["nm.netmask"])
                    f.write("  option routers %s;\n" % nm["nm.gateway"])
                    f.write("  option domain-name-servers %s;\n" % nm["nm.gateway"])
                    f.write("  option host-name \"%s\";\n" % nm["host"])
                    f.write("  option domain-name %s;\n" % nm["domain"])
                    f.write("}\n")
                    f.close()
