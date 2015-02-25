#!/bin/sh
cmd="$1"
${cmd} &
PROCESS=$!
while :
do
  RESULT=`ps -p ${PROCESS} -o comm=`
 
  if [ "${RESULT:-null}" = null ]; then
    wait ${PROCESS}
    exit $?
  else
    echo "-"
    sleep 20
  fi
done
exit $?
