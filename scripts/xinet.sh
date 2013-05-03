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
  grep 'disable' -v /etc/xinetd.d/$SVC | sed 's/{/{\n\tdisable = no/' > /etc/xinetd.d/$SVC.new
  mv /etc/xinetd.d/$SVC.new /etc/xinetd.d/$SVC
fi
if [ $ACTION == "disable" ]
then
  grep 'disable' -v /etc/xinetd.d/$SVC | sed 's/{/{\n\tdisable = yes/' > /etc/xinetd.d/$SVC.new
  mv /etc/xinetd.d/$SVC.new /etc/xinetd.d/$SVC
fi
