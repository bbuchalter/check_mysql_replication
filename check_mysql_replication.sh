#!/bin/bash

#TODO
# tmp files not cleaned up automatically

# Nagios alert status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
REPL_DIFFERENCE=1

usage="
Description: Checks master and slave log positions as well as slave status.

Usage: $0 -H <slave_host>

Script assumes:
 * it is run from the master server
 * ~/.my.cnf is configured with account which has privileges to SHOW MASTER STATUS and SHOW SLAVE STATUS.
 * English locale

More info at http://blog.endpoint.com/2012/01/mysql-replication-monitoring-on-ubuntu.html
"

if [ -z $1 ]
then
    echo "$usage"
    exit $STATE_UNKNOWN
fi

while :; do
    case "$1" in
        '')
            echo $usage
            exit $STATE_UNKNOWN
            ;;
        -h)
            echo $usage
            exit $STATE_UNKNOWN
            ;;
        -H)
            SLAVEHOST=$2
            shift
            ;;
        *) 
            echo "Unknown argument: $1"
            echo $usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift

    test -n "$1" || break
done

slave_status_file=`mktemp`
slave_error_file=`mktemp`
slave_connection_check=`mysql -h $SLAVEHOST -e "show slave status" >$slave_status_file 2>$slave_error_file`
if [[ $? -ne 0 ]]
then
    echo "Error reading slave: $(cat $slave_error_file)"
    exit $STATE_UNKNOWN
fi
rm -f $slave_error_file

master_status_file=`mktemp`
master_error_file=`mktemp`
master_connection_check=`mysql -e "show master status" >$master_status_file 2>$master_error_file`
if [[ $? -ne 0 ]]
then
    echo "Error reading master: $(cat $master_error_file)"
    exit $STATE_UNKNOWN
fi
rm -f $master_error_file

iSlave_1_position=`grep bin $slave_status_file | cut -f7`
iSlave_1_status=`grep bin $slave_status_file | cut -f1`
rm -f $slave_status_file

iMaster_position=`grep bin $master_status_file | cut -f2`
rm -f $master_status_file

iDiff_1=`expr $iMaster_position - $iSlave_1_position`

if [ $iDiff_1 -gt $REPL_DIFFERENCE ]
then
    echo "CRITICAL - master log $iMaster - slave log $iSlave_1 - log positions differ by more than $CRITICAL_VALUE"
    exit $STATE_CRITICAL
elif [ "$iSlave_1_status" != "Waiting for master to send event" ]
then
    echo "CRITICAL - slave status is '$iSlave_1_status'"
    exit $STATE_CRITICAL
else
    echo "OK - log positions match ($iMaster_position = $iSlave_1_position), slave status = '$iSlave_1_status'"
    exit $STATE_OK
fi
