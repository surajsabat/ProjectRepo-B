#!/bin/ksh
# sysfiles.sh
# RAS
# creates system files from SVN
#####################################################################
# make changes/additions for environments to the DIR_USER
# variable. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
# DIR_USER= env dir name|env user|java rev
#
#
# Modified 08/22/2014 : Sarasugi
#						1) Added one more DR node - mxpedr1k
# Modified 10/06/2014 : Vijay - Added umask command to allow only read /write permission enabled for instance owner.
# Modified 01/30/2019: Vijay Noble- Keysight-ERI - Modified the instance names
#####################################################################
#Keysight-ERI - START
DIR_USER="3ddev|mxdev|latest\n
          3dinteg|mxinteg|latest\n
          3dfulldev|mxfulld|latest\n
          3dbst|mxbst|latest\n
          prod|apache|latest\n
         "
#Keysight-ERI- END
###################################################################
# Environment declarations
###################################################################
PRG=$0
ENV=$1
SVNUSER=$2
SVNPSWD=$3
NODE=`uname -n`
USR=$(whoami)
ERR=0
MOVE=$4
SEDCMD=/bin/sed
MVCMD=/bin/mv
CMCMD=/bin/chmod
#build the mergedata name
MERGDATA="${ENV}-$NODE"

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
JAVA_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`

SOURCEDIR=/opt/matrixone/$DIR
JAVA_HOME=$SOURCEDIR/java/$JAVA_VER
LOGDIR=/opt/matrixone/$DIR/logs/svn
TOOLDIR=/opt/matrixone/tools/mms

##Allow read and write permission to be enabled for instance owner and prevent permissions for others
umask u=rwx,g=,o=

###################################
Usage() {
 print ""
 print "Generates Instance specific SystemFiles from SVN and"
 print "places them in the svn directory of the instance tree."
 print "Then executing the movetemplate.sh System Files script will manually"
 print "move the files into place. OR by adding the optional 1 to the"
 print "end of this command it will automatically move them."
 print "A log file will be placed in the svn log directory."
 print "You must be the Instance owner to run this script."
 print
 print "Usage: $PRG <instance> <user> <passwd> <move>"
 print "       instance - instance name"
 print "       user - SVN user"
 print "       passwd - SVN password"
 print "       OPTIONAL: move - 1 moves files into place"
 print
 }
#####################################

############################################################################
# main
############################################################################
#first some tests
if (($# < 3)); then
  Usage
  exit
fi

if [[ $ENV != $DIR ]]; then
  print ""
  print "   Error: Instance not defined.\n"
  exit
fi

if [[ ! -d $SOURCEDIR ]]; then
  print ""
  print "   Error: Instance doesn't exist on this box.\n"
  exit
fi

if [[ $USR != $USER ]]; then
  print ""
  print "    Error: You must be the instance owner to run this script.\n"
  exit
fi

# lets start with a clean sysfile area
 if [[ -d $SOURCEDIR/svn/systemfiles ]]; then
   /bin/rm -rf $SOURCEDIR/svn/systemfiles/*
   ERR=$?
 else
   /bin/mkdir $SOURCEDIR/svn/systemfiles
   ERR=$?
 fi

 #lets clean up the log
 if [[ $ERR -eq 0 ]] ; then
    if [[ -a $LOGDIR/systemfiles.log ]]; then
      /bin/rm -rf $LOGDIR/systemfiles.log
      ERR=$?
    fi
 fi

if [[ $ERR -eq 0 ]] ; then
   $JAVA_HOME/bin/java -Dconf=$TOOLDIR/systemfiles.conf -Dusername=$SVNUSER -Dpassword=$SVNPSWD -jar $TOOLDIR/systemfiles.jar create $MERGDATA
   ERR=$?
fi

if [[ $ERR -ne 0 ]] ; then
  print ""
  print "    Error: $ERR"
  return $ERR
fi
#Keysight-ERI : Commented
#need to edit external apaches for httpd-ssl.conf
#if [[ "$NODE" == "mxdecos1" || "$NODE" == "mxpecos1" || "$NODE" == "mxpecos2" || "$NODE" == "mxpedr1k" ]] ; then
#   $SEDCMD 's|Redirect /ematrix/common/emxNavigator.jsp|#Redirect /ematrix/common/emxNavigator.jsp|' $SOURCEDIR/svn/systemfiles/httpd-ssl.conf > $SOURCEDIR/svn/systemfiles/tmpfile
#   $MVCMD $SOURCEDIR/svn/systemfiles/tmpfile $SOURCEDIR/svn/systemfiles/httpd-ssl.conf
#fi

#change the move scrit to be executable
$CMCMD 755 $SOURCEDIR/svn/systemfiles/movetemplates.sh
ERR=$?

#now move the files is requested
if [[ $ERR -eq 0 && $MOVE -eq 1 ]] ; then
   print "Now moving the files into place"
   $SOURCEDIR/svn/systemfiles/movetemplates.sh
   ERR=$?
fi
return $ERR
