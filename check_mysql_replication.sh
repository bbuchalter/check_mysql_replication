#!/bin/bash

# Nagios alert status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

REPL_DIFFERENCE=1

usage1="
Description: Checks master and slave log positions as well as slave status.

Usage: $0 -H <slave_host>

NOTE: Script assumes:
 * it is run from the master server
 * ~/.my.cnf is configured with account which has privileges to SHOW MASTER STATUS and SHOW MASTER STATUS."

if [ -z $1 ]
then
echo "$usage1"
exit $STATE_UNKNOWN
fi

while true; do
    case "$1" in
        '')
            echo $usage1;
            exit $STATE_UNKNOWN
            ;;
        -h)
            echo $usage1;
            exit $STATE_UNKNOWN
            ;;
        -H)
            SLAVEIP_1=$2
            shift
            ;;
        *) 
            echo "Unknown argument: $1"
            echo $usage1;
            exit $STATE_UNKNOWN
            ;;
    esac
    shift

    test -n "$1" || break
done


iSlave_1_position=`mysql -h $SLAVEIP_1 -e "show slave status" | grep bin | cut -f7`

iSlave_1_status=`mysql -h $SLAVEIP_1 -e "show slave status" | grep bin | cut -f1`

iMaster=`mysql -e "show master status" | grep bin | cut -f2`

iDiff_1=`expr $iMaster - $iSlave_1_position`

if [ $iDiff_1 -gt $REPL_DIFFERENCE ]
then
echo "CRITICAL - master log $iMaster - slave log $iSlave_1 - log positions differ by more than $CRITICAL_VALUE"
exit $STATE_CRITICAL
elif [ "$iSlave_1_status" != "Waiting for master to send event" ]
then
echo "CRITICAL - slave status is '$iSlave_1_status'"
exit $STATE_CRITICAL
else
echo "OK - log positions match ($iMaster == $iSlave_1_position), slave status = '$iSlave_1_status'"
exit $STATE_OK
fi
