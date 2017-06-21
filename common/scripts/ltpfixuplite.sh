#!/bin/sh

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`
echo "Script path is: $SCRIPTPATH"
# List of test cases to be skipped
SKIPFILE=""

LTP_PATH=/opt/ltp

while getopts T:S:P:s: arg
    do case $arg in
        S) OPT=`echo $OPTARG | grep "http"`
           if [ -z $OPT ] ; then
             SKIPFILE="-S $SCRIPTPATH/ltp/$OPTARG"
           else
             wget $OPTARG
             SKIPFILE=`echo "${OPTARG##*/}"`
             SKIPFILE="-S `pwd`/$SKIPFILE"
           fi
           ;;
        P) LTP_PATH=$OPTARG;;
        s) PATTERNS="-s $OPTARG";;
    esac
done

cd $LTP_PATH
RESULT=pass

exec 4>&1
error_statuses="`((./runltplite.sh -p -q -l $SCRIPTPATH/LTP_$LOG_FILE.log $SKIPFILE $PATTERNS ||  echo "0:$?" >&3) |
        (tee $SCRIPTPATH/LTP_$LOG_FILE.out ||  echo "1:$?" >&3)) 3>&1 >&4`"
exec 4>&-

! echo "$error_statuses" | grep '0:' >/dev/null
if [ $? -ne 0 ]; then
    RESULT=fail
fi
lava-test-case LTP_$LOG_FILE --result $RESULT
cat $SCRIPTPATH/LTP_*.log
exit 0
