#!/bin/ksh
############################################################################
#
# x3d_control.sh - Script for Starting/Stopping tomee for 3DEXPERIENCE
#
# Author : Vijay Noble
# Date :   Nov 12, 2018
#
# Change History:
#
#   2018.12.09 - Initial Revision
#   2018.12.09 - Suraj- Added code for multiple JVMs
############################################################################

#####################################################################
# make changes/additions for environments to the DIR_USER
# variable. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
# DIR_USER= env dir name|env user||tomee rev|java rev|3D ver|jvm count
#####################################################################

DIR_USER="3dvan|mxvan|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|1\n
          3dfulldev|mxfulld|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|1\n
          3dinteg|mxinteg|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|1\n
          3ddev|mxdev|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|1\n
          3dbst|mxbst|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|3\n
          prod|apache|tomee_3dpassport|tomee_3dcomment|tomee_3ddashboard|tomee_3dfcs|tomee_3dspace|tomee_3dspacenocas|tomee_3dfedsearch|latest|r2017x|3\n
         "



###################################################################
# Environment declarations
###################################################################

PRG=$0
CMD=$1
ENV=$2
USR=$(whoami)

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
TOMEE_PASS=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
TOMEE_COMMENT=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
TOMEE_DASH=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
TOMEE_FCS=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
TOMEE_SPACE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`
TOMEE_SPACENOCAS=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $8}'`
TOMEE_FEDSEARCH=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $9}'`
JAVA_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $10}'`
X3D_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $11}'`
JVMCNT=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $12}'`

#CATALINA HOME
PASSCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_PASS
DASHCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_DASH
COMCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_COMMENT
FCSCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_FCS
SPACECATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_SPACE
SPACENOCASCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_SPACENOCAS
FEDSEARCHCATALINA_HOME=/opt/matrixone/$ENV/apache/$TOMEE_FEDSEARCH

#TEMP DIR
PASSCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_PASS
DASHCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_DASH
COMCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_COMMENT
FCSCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_FCS
SPACECATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_SPACE
SPACENOCASCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_SPACENOCAS
FEDSEARCHCATALINA_TMPDIR=/opt/matrixone/$ENV/temp/$TOMEE_FEDSEARCH

#X3D Home
X3D_HOME=/opt/matrixone/$DIR/$X3D_VER/3dspace/server

#XBOM home
HTTPD_HOME=/opt/matrixone/$ENV/$X3D_VER/3dspace/XMLERPIntegration/bin

#Java
JAVA_HOME=/opt/matrixone/$ENV/java/$JAVA_VER
PATH=$JAVA_HOME/bin:$PATH

#Logs
SAVE_LOGS_HOME=/matrixone/cache/$ENV
LOGS_HOME=/opt/matrixone/$ENV/logs
TEMP_HOME=/opt/matrixone/$ENV/temp

export PATH HTTPD_HOME X3D_HOME FEDSEARCHCATALINA_TMPDIR SPACENOCASCATALINA_TMPDIR SPACECATALINA_TMPDIR PASSCATALINA_TMPDIR DASHCATALINA_TMPDIR COMCATALINA_TMPDIR FCSCATALINA_TMPDIR SPACECATALINA_HOME SPACENOCASCATALINA_HOME FEDSEARCHCATALINA_HOME PASSCATALINA_HOME DASHCATALINA_HOME COMCATALINA_HOME FCSCATALINA_HOME LOGS_HOME JAVA_HOME

############################################################################
# Usage
############################################################################
#| awk -F "\n" '{print $1}'
Usage() {
 INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
 INSTANCES=`echo $INSTANCES`
 print "Usage: $PRG <command> <environment>"
 print
 print "       Commands = all_start all_stop"
 print "                 all_debug save_logs"
 print "       Environments = $INSTANCES"
 print
}

##########################################################################
# Savelogs
###########################################################################

Savelogs() {

  print "Saving 3space, ERP and tomee log files ..."
  LOGDIRDATE=`date +%Y'_'%m'_'%d'_'%H%M`
  LOGDIR=$SAVE_LOGS_HOME/${ENV}_logs-$LOGDIRDATE

  if [[ $USR != $USER ]]; then
    su $USER -c "mkdir -p $LOGDIR"
    su $USER -c "cp -R $LOGS_HOME/* $LOGDIR"
  else
    mkdir -p $LOGDIR
    cp -R $LOGS_HOME/* $LOGDIR
  fi
  print "Logs copied to $LOGDIR\n"
}
############################################################################
# Starttomee
# The catalina.sh script has several options for start, debug, etc.
############################################################################

Starttomee() {

print "Removing tomee log files..."

if [ -d $DASHCATALINA_HOME ]; then
rm -f $LOGS_HOME/tomee/3ddashboard/*log
# Lets remove juli* logs
print "Removing 3DDashboard juli logs..."
rm -f $DASHCATALINA_HOME/logs/juli*
fi

if [ -d $COMCATALINA_HOME ]; then  
rm -f $LOGS_HOME/tomee/3dcomment/*log
# Lets remove juli* logs
print "Removing 3DComment juli logs..."
rm -f $COMCATALINA_HOME/logs/juli*
fi

if [ -d $PASSCATALINA_HOME ]; then  
rm -f $LOGS_HOME/tomee/3dpassport/*log
# Lets remove juli* logs
print "Removing juli logs..."
rm -f $PASSCATALINA_HOME/logs/juli*
fi

if [ -d $FCSCATALINA_HOME ]; then  
rm -f $LOGS_HOME/tomee/*log
# Lets remove juli* logs
print "Removing juli logs..."
rm -f $FCSCATALINA_HOME/logs/juli*
fi

integer count=1
while (( count <= JVMCNT ))
    do
    if [ -d $SPACECATALINA_HOME$count ]; then  
      rm -f $LOGS_HOME/tomee/3dspace/*log
      # Lets remove juli* logs
      print "Removing 3dspace juli logs..."
      rm -f $SPACECATALINA_HOME$count/logs/juli*
	  print "Removing 3dspace temp files..."
	  rm -rf $TEMP_HOME/tomee/3dspace/temp$count/*
    fi
    (( count = count + 1))
done

if [ -d $SPACENOCASCATALINA_HOME ]; then  
rm -f $LOGS_HOME/tomee/3dspacenocas/*log
# Lets remove juli* logs
print "Removing 3dspacenocas juli logs..."
rm -f $SPACENOCASCATALINA_HOME/logs/juli*
fi

if [ -d $FEDSEARCHCATALINA_HOME ]; then  
rm -f $LOGS_HOME/tomee/3dfedsearch/*log
# Lets remove juli* logs
print "Removing 3dfedsearch juli logs..."
rm -f $FEDSEARCHCATALINA_HOME/logs/juli*
fi

#Remove the cache contents
if [[ -d $X3D_HOME/mxcache ]]; then
   rm -rf $X3D_HOME/mxcache/*
fi

#Remove 3dspace logs
#rm -f $LOGS_HOME/3dspace/rmi/*log
if [[ -d $LOGS_HOME/3dspace ]]; then
   rm -f $LOGS_HOME/3dspace/*log
fi

#Mode
if [[ $MODE = "start" ]]; then
   print "Starting $ENV tomee ..."
else
   print "Starting $ENV tomee in DEBUG mode"
fi

#Probably dont need to send output to log as only catches catalina.sh script errors
#Start Passport
if [ -d $PASSCATALINA_HOME ]; then  
echo "Starting 3DPassport tomee Mode is $MODE" > $LOGS_HOME/tomee/3dpassport/tomee_start.log
echo "PASSCATALINA_HOME is: $PASSCATALINA_HOME" >> $LOGS_HOME/tomee/3dpassport/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $PASSCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dpassport/tomee_start.log 2>&1 &"
else
  nohup $PASSCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dpassport/tomee_start.log 2>&1 &
fi
echo "$ENV 3DPassport tomee started" >> $LOGS_HOME/tomee/3dpassport/tomee_start.log
print "$ENV 3DPassport tomee started"
fi

#Start Dashboard
if [ -d $DASHCATALINA_HOME ]; then  
echo "Starting 3DDashboard tomee Mode is $MODE" > $LOGS_HOME/tomee/3ddashboard/tomee_start.log
echo "DASHCATALINA_HOME is: $DASHCATALINA_HOME" >> $LOGS_HOME/tomee/3ddashboard/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $DASHCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3ddashboard/tomee_start.log 2>&1 &"
else
  nohup $DASHCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3ddashboard/tomee_start.log 2>&1 &
fi
echo "$ENV 3DDashboard tomee started" >> $LOGS_HOME/tomee/3ddashboard/tomee_start.log
print "$ENV 3DDashboard tomee started"
fi

#Start Comment
if [ -d $COMCATALINA_HOME ]; then  
echo "Starting 3DComment tomee Mode is $MODE" > $LOGS_HOME/tomee/3dcomment/tomee_start.log
echo "COMCATALINA_HOME is: $COMCATALINA_HOME" >> $LOGS_HOME/tomee/3dcomment/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $COMCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dcomment/tomee_start.log 2>&1 &"
else
  nohup $COMCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dcomment/tomee_start.log 2>&1 &
fi
echo "$ENV 3DComment tomee started" >> $LOGS_HOME/tomee/3dcomment/tomee_start.log
print "$ENV 3DComment tomee started"
fi

#Start FCS
if [ -d $FCSCATALINA_HOME ]; then  
echo "Starting FCS tomee Mode is $MODE" > $LOGS_HOME/tomee/tomee_start.log
echo "FCSCATALINA_HOME is: $FCSCATALINA_HOME" >> $LOGS_HOME/tomee/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $FCSCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/tomee_start.log 2>&1 &"
else
  nohup $FCSCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/tomee_start.log 2>&1 &
fi
echo "$ENV FCS tomee started" >> $LOGS_HOME/tomee/tomee_start.log
print "$ENV FCS tomee started"
fi

#Start 3DFedSearch
if [ -d $FEDSEARCHCATALINA_HOME ]; then  
echo "Starting 3DFedSearch tomee Mode is $MODE" > $LOGS_HOME/tomee/3dfedsearch/tomee_start.log
echo "FEDSEARCHCATALINA_HOME is: $FEDSEARCHCATALINA_HOME" >> $LOGS_HOME/tomee/3dfedsearch/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $FEDSEARCHCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dfedsearch/tomee_start.log 2>&1 &"
else
  nohup $FEDSEARCHCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dfedsearch/tomee_start.log 2>&1 &
fi
echo "$ENV 3DFedSearch tomee started" >> $LOGS_HOME/tomee/3dfedsearch/tomee_start.log
print "$ENV 3DFedSearch tomee started"
fi

# Start XBOM service
if [[ -x $HTTPD_HOME/httpd.sh ]]; then
    print "Starting ERP Adapter"
    if [[ $USR != $USER ]]; then
      su $USER -c "nohup $HTTPD_HOME/httpd.sh > $LOGS_HOME/ERPAdapter/start.log 2>&1 &"
    else
      nohup $HTTPD_HOME/httpd.sh > $LOGS_HOME/ERPAdapter/start.log 2>&1 &
    fi
else
  print "ERP Adapter NOT started, MXOMFG will not work on this server."
fi

integer count=1
#Start 3dspace
while (( count <= JVMCNT ))
	do
    if [ -d $SPACECATALINA_HOME$count ]; then  
      echo "Starting 3dspace tomee Mode is $MODE" > $LOGS_HOME/tomee/3dspace/tomee_start.log
      echo "SPACECATALINA_HOME is: $SPACECATALINA_HOME$count" >> $LOGS_HOME/tomee/3dspace/tomee_start.log
      if [[ $USR != $USER ]]; then
         su $USER -c "nohup $SPACECATALINA_HOME$count/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dspace/tomee_start.log 2>&1 &"
      else
         nohup $SPACECATALINA_HOME$count/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dspace/tomee_start.log 2>&1 &
      fi
      echo "$ENV 3dspace $count tomee started" >> $LOGS_HOME/tomee/3dspace/tomee_start.log
      print "$ENV 3dspace$count tomee started"
    fi
    (( count = count + 1))
done
#Start 3dspacenocas
if [ -d $SPACENOCASCATALINA_HOME ]; then  
echo "Starting 3dspacenocas tomee Mode is $MODE" > $LOGS_HOME/tomee/3dspacenocas/tomee_start.log
echo "SPACENOCASCATALINA_HOME is: $SPACENOCASCATALINA_HOME" >> $LOGS_HOME/tomee/3dspacenocas/tomee_start.log
if [[ $USR != $USER ]]; then
  su $USER -c "nohup $SPACENOCASCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dspacenocas/tomee_start.log 2>&1 &"
else
  nohup $SPACENOCASCATALINA_HOME/bin/catalina.sh $MODE >> $LOGS_HOME/tomee/3dspacenocas/tomee_start.log 2>&1 &
fi
echo "$ENV 3dspacenocas tomee started" >> $LOGS_HOME/tomee/3dspacenocas/tomee_start.log
print "$ENV 3dspacenocas tomee started"
fi

}

############################################################################
# Stop tomee
############################################################################

Stoptomee() {

#Stop Passport tomee
if [ -d $PASSCATALINA_HOME ]; then  
print "Stopping $ENV 3DPassport tomee ..."
$PASSCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/3dpassport/tomee_start.log 2>&1 &
print "$ENV 3DPassport tomee Stopped.\n"
fi

#Stop Dashboard tomee
if [ -d $DASHCATALINA_HOME ]; then  
print "Stopping $ENV 3DDashboard tomee ..."
$DASHCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/3ddashboard/tomee_start.log 2>&1 &
print "$ENV 3DDashboard tomee Stopped.\n"
fi

#Stop Comment tomee
if [ -d $COMCATALINA_HOME ]; then  
print "Stopping $ENV 3DComment tomee ..."
$COMCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/3dcomment/tomee_start.log 2>&1 &
print "$ENV 3DComment tomee Stopped.\n"
fi

#Stop FCS tomee
if [ -d $FCSCATALINA_HOME ]; then  
print "Stopping $ENV FCS tomee ..."
$FCSCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/tomee_start.log 2>&1 &
print "$ENV FCS tomee Stopped.\n"
fi

#Stop 3dfedsearch tomee
if [ -d $FEDSEARCHCATALINA_HOME ]; then  
print "Stopping $ENV 3dfedsearch tomee ..."
$FEDSEARCHCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/3dfedsearch/tomee_start.log 2>&1 &
print "$ENV 3dfedsearch tomee Stopped.\n"
fi

#stop 3dspace tomee
integer count=1
while (( count <= JVMCNT ))
    do
    if [ -d $SPACECATALINA_HOME$count ]; then  
       print "Stopping $ENV 3dspace$count tomee ..."
       $SPACECATALINA_HOME$count/bin/catalina.sh stop >> $LOGS_HOME/tomee/3dspace/tomee_start.log 2>&1 &
       print "$ENV 3dspace$count tomee Stopped.\n"
    fi
    (( count = count + 1))
done

#Stop 3dspacenocas tomee
if [ -d $SPACENOCASCATALINA_HOME ]; then  
print "Stopping $ENV 3dspacenocas tomee ..."
$SPACENOCASCATALINA_HOME/bin/catalina.sh stop >> $LOGS_HOME/tomee/3dspacenocas/tomee_start.log 2>&1 &
print "$ENV 3dspacenocas tomee Stopped.\n"
fi

#Stop XBOM Service
if [[ -x $HTTPD_HOME/httpd.sh ]]; then
    print "Stoping ERP Adapter..."
    for HTTPPROC in `ps -ef | grep XMLERPIntegration | grep "$USER " | grep -v grep | awk '{print $2}'`
       do
         print "  Killing httpd process: $HTTPPROC"
         kill -9 $HTTPPROC
       done
fi

killJVM
print "$ENV Clear JVM.\n"
}

############################################################################
# killJVM
#
#   Requires:
#     USR           - Effective User ID of user running this script
#     ENV           - Target 3DEXPERIENCE Environment
#     ENV_USER      - User Id of "Owner" of the Target Environment
#
############################################################################

killJVM() {

print "Stopping $ENV java processes..."
for KILLPID in `ps -ef | grep java | grep "$USER" | grep -v grep | grep -v mms | awk '{print $2}'`
  do
    print "  Killing process: $KILLPID"
    kill -9 $KILLPID
done

  print "Checking for any hanging java processes. please wait..."
  sleep 5
  ps -ef | grep java | grep "$USER" | grep -v grep | grep -v mms
}

############################################################################
# main
############################################################################

if (($# < 2)); then
  Usage
  exit
fi

if [[ "$DIR" != "$ENV" ]]; then
  print "Error: Unrecognized environment: $ENV"
  Usage
  exit
fi

if [[ $USR != "root" && $USR != $USER ]]; then
  print "Error: You must be root or the environment owner to run this script.\n"
  exit
fi

case $CMD in
     all_start)   MODE="start"
                  Starttomee
                   ;;
     all_debug)   MODE="jpda start"
                  Starttomee
                   ;;
     all_stop)    Stoptomee
                   ;;
     save_logs)   Savelogs
                   ;;
  *)              print "Error: Unrecognized command: $CMD"
                  Usage
                  exit
                   ;;
esac

return 0
