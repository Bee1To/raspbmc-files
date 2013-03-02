#!/bin/bash
autoip=$(ip addr | grep eth0:autoip | grep -v inet6 | grep inet)
netaddr=$(ip addr | grep eth0 | grep -v eth0:autoip | grep -v inet6 | grep inet)
while [ '$netaddr' = '' ]; do  
         if [ '$autoip' = '' ]; then  
             ifconfig eth0:autoip 169.254.0.100 netmask 255.255.0.0 up 2>&1 | logger -t network-autoip 
         fi
         sleep 5
         netaddr=$(ip addr | grep eth0 | grep -v eth0:autoip | grep -v inet6 | grep inet )
         autoip=$(ip addr | grep eth0:autoip | grep -v inet6 | grep inet)
done

