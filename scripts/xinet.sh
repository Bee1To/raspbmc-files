#!/bin/bash
ACTION=$1
SVC=$2
if [ "$ACTION" == "status" ]
then
  res=$(grep disable /etc/xinetd.d/$SVC | awk '{print $3}')
  if [ "$res" == "no" ]
  then
  echo 1
  fi
  if [ "$res" == "yes" ]
  then
  echo 0
  fi
fi
if [ "$ACTION" == "enable" ]
then
grep -E 'disable|}' -v /etc/xinetd.d/$SVC > /etc/xinetd.d/$SVC.new
mv /etc/xinetd.d/$SVC.new /etc/xinetd.d/$SVC
echo "disable = no
}" >> /etc/xinetd.d/$SVC
fi
if [ "$ACTION" == "disable" ]
then
grep -E 'disable|}' -v /etc/xinetd.d/$SVC > /etc/xinetd.d/$SVC.new
mv /etc/xinetd.d/$SVC.new /etc/xinetd.d/$SVC
echo "disable = yes
}" >> /etc/xinetd.d/$SVC
fi

