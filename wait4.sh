#!/bin/sh
PROCESS="$1"
while :
do
  RESULT=`ps -p ${PROCESS} -o comm=`
 
  if [ "${RESULT:-null}" = null ]; then
    break
  else
    echo "-"
    sleep 20
  fi
done
