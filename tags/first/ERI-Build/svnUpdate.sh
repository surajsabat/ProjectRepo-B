#!/bin/ksh
############################################################################
#
# SVNpdate - This script updates the SVN vendor branch from an instance
#
# Author : Ric Schug
# Date :   Mar 10, 2010
#
# Change History:
#
#   3/10/2010 - Initial Revision
#   4/16/2014 - Updated Email Address
#   06/13/2014 Sarasugi - Changed SVN url - http://tcssvn.cos.is.keysight.com
#	12/10/2014 Sharmila T C - Redmine 716 Updated mail id to keysight
#   03/08/2018 Vijay Noble - RM:1766 - Replaced SVN server http://tcssvn.cos.is.keysight.com with http://cossvn.is.keysight.com
#   03/04/2019 Vijay Noble - Keysight-ERI, Replaced v6 to 3d environment
############################################################################
#####################################################################
# make changes/additions for environments to the DIR_USER
# variable. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
# DIR_USER= env dir|env user|node|M1 rev
#####################################################################

DIR_USER="3dvan|mxvan|mxdap3|r2017x\n
         "
###################################################################
# Environment declarations
###################################################################

PRG=$0
OPT=$1
ENV=$2
PSWD=$3
BRANCH=$4
SVNUSER=$5
SVNPSWD=$6
USR=$(whoami)
NODE=$(uname -n)
SVNCMD=/opt/CollabNet_Subversion/bin/svn
EMAIL=hasu_modi@keysight.com
LOGDATE=`date +%Y'_'%m'_'%d'_'%H%M`

ERR=0

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
SNODE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
X3D_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`

INSDIR=/opt/matrixone/$DIR/
SOURCEDIR=/opt/matrixone/$DIR/$X3D_VER/3dspace
MQLCMD=$SOURCEDIR/server/scripts/mql
LOGFILE=/opt/matrixone/$DIR/logs/svn/svnUpdate_$LOGDATE.log

############################################################################
# Usage
############################################################################

Usage() {
 INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
 INSTANCES=`echo $INSTANCES`
 print "Usage: $PRG <option> <instance> <passwd> <svn branch> <svn user> <svn passwd>"
 print
 print "       Based on the specified option gathers up data and checks it into SVN."
 print "       You need to be the environment owner to run this script. See the "
 print "         svnUpdate log file in /tmp for details of actions."
 print "       If no branch parameters are specified then the svn staging directory is loaded"
 print "         but no checkin is performed. "
 print "       Checkins are only performed for the vendor and tags folders. "
 print "         A vendor checkin will include the tree, war files, and exports. "
 print "         A tag checkin will create a new branch from the Trunk and include the war files and exports "
 print "           from the instance specified."
 print "       instance = name of instance to pull from "
 print "       passwd = instance creator password"
 print "       The following are optional but must use all 3 or none"
 print "         svn branch = new svn branch to checkin to; specify path under vendor or under tags "
 print "                      (ex:dassault/v6r2010x-1033, use Version and Fix Pack number ) "
 print "         svn user = svn user who will execute the checkin "
 print "         svn passwd = password for the svn user "
 print "       option: "
 print "               1 = vendor branch checkin (collect tree,create spinner files, create exports and checkin everything)"
 print "               2 = tag branch creation (create tag branch from Trunk and checkin exports and war files"
 print "       Environments = $INSTANCES"
}

############################################################################
# Plog (message)
# put message in log file
############################################################################
Plog() {
  MSG=$1
  echo $MSG >> $LOGFILE
}

############################################################################
# CopyDir (From To)
# copies directory
############################################################################
CopyDir() {
  FROM=$1
  TO=$2

  /bin/cp -pfr $FROM $TO 2>>$LOGFILE
  if [[ $? -ne 0 ]] ; then
    Plog "Copy of $FROM directory failed"
    exit 1
  fi
  return 0
}

############################################################################
# Mail (Message)
# sends mail to specified user
############################################################################
Smail() {
  MSG=$1
  mail -s "SVNUpdate Status $ERR" $EMAIL < $MSG
}

############################################################################
# CopyTree
# copies tree to svn staging dir
############################################################################
CopyTree() {
  Plog "Now copying the file tree"
  if [[ -d $INSDIR/svn/ematrix ]]; then
     /bin/rm -rf $INSDIR/svn/ematrix/* 2>>$LOGFILE
   else
     /bin/mkdir $INSDIR/svn/ematrix 2>>$LOGFILE
   fi

  CopyDir $SOURCEDIR/studio $INSDIR/svn/ematrix
  CopyDir $SOURCEDIR/server $INSDIR/svn/ematrix
  CopyDir $INSDIR/$X3D_VER/bootstraps $INSDIR/svn/ematrix
  if [[ -d $SOURCEDIR/XMLERPIntegration ]]; then
     CopyDir $SOURCEDIR/XMLERPIntegration $INSDIR/svn/ematrix
  fi
  /bin/rm -rf $INSDIR/svn/ematrix/server/distrib/* 2>>$LOGFILE
  /bin/rm -rf $INSDIR/svn/ematrix/server/distrib_CAS/* 2>>$LOGFILE
  /bin/rm -rf $INSDIR/svn/ematrix/server/distrib_NoCAS/* 2>>$LOGFILE
}

############################################################################
# CreateSpinner
# creates all spinner files
############################################################################
CreateSpinner() {
   Plog "Now creating the Spinner files"
   /bin/rm -rf $INSDIR/svn/Spinner/* 2>>$LOGFILE
   SPINDATE=`date +%Y%m%d`
   #$MQLCMD -d -t -c "set context user creator password $PSWD; exec prog create_svn_spin.tcl $SOURCEDIR $LOGFILE $ENV" > /dev/null
   $MQLCMD -d -t -c "set context user creator password $PSWD;exec prog emxExtractSchema.tcl * *;" > /dev/null
   CopyDir /tmp/SpinnerAgent$SPINDATE/* $INSDIR/svn/Spinner/
}
############################################################################
# WarExport
# creates exports and grabs war file
############################################################################
WarExport() {
   Plog "Now creating the Exports"

   if [[ -d $INSDIR/svn/ematrix/Build ]]; then
     /bin/rm -rf $INSDIR/svn/ematrix/Build/* 2>>$LOGFILE
   else
     /bin/mkdir $INSDIR/svn/ematrix/Build 2>>$LOGFILE
   fi

   # first get schema - do we want to add and exclude
   CMD="export admin * !mail !set !archive into file $INSDIR/svn/ematrix/Build/schema.exp"
   $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE

   # now get business admin stuff
   if [[ $ENV == "3dvan" ]]; then
     CMD="export bus * * * from vault \"eService Administration\" !history !relationship into file $INSDIR/svn/ematrix/Build/Administration.exp"
   else
     CMD="export bus * * * from vault Administration !history !relationship into file $INSDIR/svn/ematrix/Build/Administration.exp"
   fi
   $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE

   CMD="export bus * * * from vault \"TVC Administration\" !history !relationship into file $INSDIR/svn/ematrix/Build/tvcadmin.exp"
   $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE

   Plog "Now copying the war and static files"
   CopyDir $SOURCEDIR/server/distrib_CAS/3dspace.war $INSDIR/svn/ematrix/Build
   CopyDir $SOURCEDIR/server/distrib_CAS/3dspace_static.zip $INSDIR/svn/ematrix/Build
   CopyDir $SOURCEDIR/server/distrib_NoCAS/internal.war $INSDIR/svn/ematrix/Build
   CopyDir $SOURCEDIR/server/distrib_NoCAS/internal_static.zip $INSDIR/svn/ematrix/Build
}

############################################################################
# SVNCreate
# create an  svn branch
# 03/08/2018 Vijay Noble - RM:1766 - Replaced SVN URL http://tcssvn.cos.is.keysight.com with http://cossvn.is.keysight.com
############################################################################
SVNCreate() {
 if [[ $BRANCH != "" && $SVNUSER != "" && $SVNPSWD != "" ]]; then
   if (($OPT == 1)); then
      Plog "Now check everything into vendor branch $BRANCH"
      # import new branch
      $SVNCMD import -q -m "New branch created by svnUpdate from instance $ENV" --non-interactive --username $SVNUSER --password $SVNPSWD $INSDIR/svn http://cossvn.is.keysight.com/svn/MatrixOne/vendor/$BRANCH 2>> $LOGFILE

      # now do delete & create current17x and checkin war
      VDR=`echo -e $BRANCH | sed 's/^ //' | awk -F '/' '{print $1}'`
      BCH=`echo -e $BRANCH | sed 's/^ //' | awk -F '/' '{print $2}'`

      Plog "Updating the current17x branch under vendor"
      $SVNCMD delete -q -m "Removing current17x branch to be replaced by $BRANCH" --non-interactive --username $SVNUSER --password $SVNPSWD http://cossvn.is.keysight.com/svn/MatrixOne/vendor/$VDR/current17x 2>> $LOGFILE
      $SVNCMD copy -q -m "Copying $BRANCH to current17x branch" --non-interactive --username $SVNUSER --password $SVNPSWD http://cossvn.is.keysight.com/svn/MatrixOne/vendor/$BRANCH http://cossvn.is.keysight.com/svn/MatrixOne/vendor/$VDR/current17x 2>> $LOGFILE
   else if (($OPT == 2)); then
      # copy the tag from trunk
      Plog "Creating new tags/$BRANCH from the Trunk"
      $SVNCMD copy -q -m "Copy Trunk to $BRANCH tag" --non-interactive --username $SVNUSER --password $SVNPSWD http://cossvn.is.keysight.com/svn/MatrixOne/Trunk http://cossvn.is.keysight.com/svn/MatrixOne/tags/$BRANCH 2>> $LOGFILE

      # now checkin war
      Plog "Checking exports into tags/$BRANCH"
      $SVNCMD import -q -m "Adding war files and exports to $BRANCH" --non-interactive --username $SVNUSER --password $SVNPSWD $INSDIR/svn/ematrix/Build http://cossvn.is.keysight.com/svn/MatrixOne/tags/$BRANCH/ematrix/Build 2>> $LOGFILE
    fi
   fi
 else
    Plog "SVN information not specified; nothing checked into SVN"
 fi
}

############################################################################
# Main
############################################################################
# lets do some initial tests
if (($# < 3)); then
  print "Wrong number of Arguments"
  Usage
  exit
fi

if [[ $ENV != $DIR ]]; then
  print "Error: Environment not configured for SVN uploads."
  exit
fi

if [[ $USR != $USER ]]; then
  print "Error: You must be the environment owner to run this script."
  exit
fi

if [[ $SNODE != $NODE ]]; then
  print "Error: You must be on the machine $SNODE to run this script."
  exit
fi

Plog "This script was run as SVN user: $SVNUSER at `date +%H:%M:%S`"
# now lets go do something
case $OPT in
  1)   	Plog "Starting the SVN Update process from instance $ENV for Option $OPT"
        CopyTree
  			CreateSpinner
  			WarExport
  			SVNCreate
            ;;
  2)    	Plog "Starting the SVN Update process from instance $ENV for Option $OPT "
         WarExport
  		   SVNCreate
           ;;
  *)     print "Error: Unrecognized Option: $OPT"
         Usage
         exit
          ;;
esac

Plog "svnUpdate.sh Finished at `date +%H:%M:%S`"
Smail $LOGFILE
return $ERR