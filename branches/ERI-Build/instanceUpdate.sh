#!/bin/ksh
############################################################################
#
# instanceUpdate - This script will update an instance either from the SVN tree
#                   or from a war file and exports.
#
# Author : Ric Schug
# Date :   Mar 30, 2010
#
# Change History:
#
#   3/30/2010 - Initial Revision
#   5/14/2010 RAS - added pdl for email and some server starts and stops because
#                   spinner was hanging if server was having issues.
#   11/18/2010 RAS - added Terrys web service workaround
#   01/9/2011 RAS - commented out Terrys workaround and added apache/tomcat to tree
#   06/28/2011 RAS - added very basic 107 capability
#   07/27/2012 RAS - changed custom dir remove to Ag_* and agc_* removal
#   02/10/2013 RAS - removed all 10.7 stuff
#   03/4/2013 RAS - added PLM Bridge (reports)
#   06/28/2013 RAS - changed URL for external portal to use gtt site
#   10/28/2013 M. Pacheva - added Support Scripts for automated instance updates
#   01/29/2014 Vijay Noble- Redmine:484 Removed export control link for external
#   05/13/2014 Vijay Noble- Redmine:666 Modified CreateTag procedure.
#   06/13/2014 Sarasugi - Changed SVN url - http://tcssvn.cos.is.keysight.com
#   07/31/2014 Sarasugi - Modified the alias for mxpsup1.cos.agilent.com:8080/
#   09/16/2014 Sarasugi - Modified the alias for External - https://us.supplychain.agilent.com to https://us.supplychain.keysight.com
#	12/10/2014 Sharmila T C - Redmine#716 Updated pdl and email ids to keysight
#	01/29/2014 Sharmila T C - Redmine#851 Updated Export control link to point to Keysight
#   01/22/2015 Vijay -RM:802-Tomcat Upgraded 
#   04/21/2015 Vijay Noble -RM:851-Updated Export control link
#   03/08/2018 Vijay Noble - RM:1766 - Replaced SVN server http://tcssvn.cos.is.keysight.com with http://cossvn.is.keysight.com
#   03/04/2019 Vijay Noble - Keysight-ERI Modified for 17x instance update.
############################################################################
#####################################################################
# make changes/additions for environments to the DIR_USER
# variable. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
# DIR_USER= env dir|env user|node|M1 rev|java rev| apache rev|tomcat rev
#####################################################################

#DIR_USER="v6dev|mxdev|mxdap1|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#          v6cad|mxnewd|mxdap2|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#          v6fulldev|mxfulld|mxdap2|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#         v6test|mxtst|mxdap1|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#         integ|mxinteg|mxdap2|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#         v6bst|mxbst2|mxdap1|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#         prod|apache|mxpsup1|enovia_v6r2012x|jdk1.6.0_30|apache_2.2.23|apache-tomcat-6.0.41\n
#        "
DIR_USER="3ddev|mxdev|mxdap3|r2017x|latest||tomee_3dspace\n
          3dfulldev|mxfulld|mxdap4|r2017x|latest||tomee_3dspace\n
          3dinteg|mxinteg|mxdap4|r2017x|latest||tomee_3dspace\n
          3dbst|mxbst|mxdap3|r2017x|latest||tomee_3dspace\n
          prod|apache|mxpsup2|r2017x|latest||tomee_3dspace\n
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
SVNPWD=$6
USR=$(whoami)
NODE=$(uname -n)
SVNCMD=/opt/CollabNet_Subversion/bin/svn
MVCMD=/bin/mv
SEDCMD=/bin/sed
CPCMD=/bin/cp
RMCMD=/bin/rm
TOOLDIR=/opt/matrixone/tools/mms
EMAIL=pdl-m1alldevelopers@keysight.com
ERR=0

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
SNODE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
X3D_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
JAVA_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
AP_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
TC_VER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`

SOURCEDIR=/opt/matrixone/$DIR
MQLCMD=$SOURCEDIR/$X3D_VER/3dspace/studio/scripts/mql
JAVA_HOME=$SOURCEDIR/java/$JAVA_VER
LOGDIR=$SOURCEDIR/logs/svn
LOGDATE=`date +%Y'_'%m'_'%d'_'%H%M`
LOGFILE=$LOGDIR/instanceUpdate_$LOGDATE.log
SUPPORT_SCRIPTS_DIR=$HOME

############################################################################
# Usage
############################################################################

Usage() {
 INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
 INSTANCES=`echo $INSTANCES`
 print "       - Based on the specified option this script will update an existing instance from SVN."
 print "       - Basically the svn staging directory is loaded from SVN and then applied to the instance. "
 print "       - Checkouts from the Trunk or tags folders will apply all Agilent chagnes and therefore "
 print "          can only be applied to an existing instance. Checkouts from the vendor folder will supply"
 print "          a more complete structure however configurations will be required before a working"
 print "          instance can be created. Note that the instance is bounced afte the updates."
 print "       - If the instance updated is Integ or BST then a Tag is created under"
 print "          the tags directory of the form Integ_<date>_<time>."
 print "       - See the installUpdate log file in /opt/matrixone/<instance name>/logs/svn for the details of actions."
 print
 print "       instance = name of instance to load "
 print "       passwd = instance creator password"
 print "       svn branch = full name of SVN branch to checkout from (ex: Trunk or tags/Integ_Nov_1110_2012 or "
 print "                    vendor/dassault/V6r2010x-1; or branches/107Enhancements) "
 print "       svn user = svn user who will execute the checkout "
 print "       svn passwd = password for the svn user "
 print "       option: "
 print "               1 = Update instance from SVN tree"
 print "               2 = Update instance from war and export files"
 print "               3 = Builds a war and moves, no restart"
 print
 print "Usage: $PRG <option> <instance> <passwd> <svn branch> <svn user> <svn passwd>"
 print
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

  /bin/cp -fLr ${FROM} ${TO} 2>>$LOGFILE
  if [[ $? -ne 0 ]] ; then
    Plog "Copy of $FROM directory failed"
    ERR=1
  else
    Plog "Copy of $FROM -to- $TO successful"
  fi
  return 0
}

############################################################################
# Smail (Message)
# sends mail to specified user
############################################################################
Smail() {
  MSG=$1
  echo "$MSG" | /bin/mail -s "SVN InstanceUpdate Completed on $ENV with status $ERR" $EMAIL
}

############################################################################
# TreeLoad
# copies the svn staging dir into instance tree
#Keysight-ERI added enterprisechangemgt and modified the path v6 to 3d
############################################################################
TreeLoad() {
 umask 002
 #if [[ $ENV != "prod" ]]; then
    Plog "First cleaning out the custom files"
    # list of dirs containing custom dirs
    set -A TREE engineeringcentral \
           common \
           components \
           documentcentral \
           businessmetrics \
           manufacturerequivalentpart \
           suppliercentral \
           iefdesigncenter \
           materialscompliance \
           integrations \
           tvc \
           macs \
           productline \
           programcentral \
           enterprisechangemgt

     COUNT=`print ${#TREE[*]}`

     integer j=0
     until [[ $j = $COUNT ]] ; do
        TARGET=$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/${TREE[$j]}
        Plog "   Deleting all Agilent files in: $TARGET"
        /bin/rm -rf $TARGET/Ag_* 2>>$LOGFILE
        /bin/rm -rf $TARGET/agc_* 2>>$LOGFILE
     j=j+1
     done

     TARGET=$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix
     Plog "   Deleting all Agilent files in: $TARGET"
     /bin/rm -rf $TARGET/Ag_* 2>>$LOGFILE
     /bin/rm -rf $TARGET/agc_* 2>>$LOGFILE

     Plog "Now copying the M1 trees from the SVN directory to the instance tree"
     #CopyDir $SOURCEDIR/svn/ematrix/studio $SOURCEDIR/$M1_VER
     #CopyDir $SOURCEDIR/svn/ematrix/server $SOURCEDIR/$M1_VER
     CopyDir $SOURCEDIR/svn/ematrix/studio $SOURCEDIR/$X3D_VER/3dspace
     CopyDir $SOURCEDIR/svn/ematrix/server $SOURCEDIR/$X3D_VER/3dspace
     Plog "Now copying the Properties and Custom jars"
	 cp -fr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
	 cp -fr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
	 cp -fr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	 cp -fr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
  #else
     #Plog "Now copying some M1 files just for mxpsup2"
     #CopyDir "$SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/*" $SOURCEDIR/$M1_VER/server/STAGING/ematrix/classes
     #CopyDir "$SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/*" $SOURCEDIR/$M1_VER/server/STAGING/ematrix/properties
 #fi

 Plog "Now copying the non-M1 trees from the SVN directory to the instance tree"
 #CopyDir "$SOURCEDIR/svn/apache/apache/*" $SOURCEDIR/apache/$AP_VER
 #CopyDir "$SOURCEDIR/svn/apache/tomcat/*" $SOURCEDIR/apache/$TC_VER
 CopyDir $SOURCEDIR/svn/ematrix/XMLERPIntegration $SOURCEDIR/$X3D_VER/3dspace

 # now lets to plm bridge
 if [[ -d $SOURCEDIR/reports ]]; then
    Plog "Now updating the PLMBridge reports directory from SVN"
    # need to address this but for now just don't delete as stuff in dir that must be kept
    #/bin/rm -rf $SOURCEDIR/reports 2>>$LOGFILE
    CopyDir $SOURCEDIR/svn/reports $SOURCEDIR
 fi

  # now let's update Support Scripts
 if [[ -d $SUPPORT_SCRIPTS_DIR/support_team_files ]]; then
    Plog "Now updating the Support Scripts directory from SVN"
    # need to address this but for now just don't delete as stuff in dir that must be kept
    #/bin/rm -rf $SUPPORT_SCRIPTS_DIR/support_team_files 2>>$LOGFILE
    CopyDir $SOURCEDIR/svn/support_team_files $SUPPORT_SCRIPTS_DIR
 fi
}

############################################################################
# SpinnerLoad
# loads all spinner files
# Keysight-ERI - commented wizard, which is not supported in 17x
############################################################################
SpinnerLoad() {
   # for now lets ignore the System stuff
   # /bin/rm -rf $SOURCEDIR/svn/Spinner/System/* 2>>$LOGFILE

   cd $SOURCEDIR/svn/Spinner
   Plog "Now running the Spinner"
   $MQLCMD -d -t -c "set context user creator password $PSWD; set escape on; exec prog emxSpinnerAgent.tcl" >> $LOGFILE 2>&1
   ERR=$?
   $MQLCMD -d -t -c "set context user creator password $PSWD; set escape off" >> $LOGFILE 2>&1

   if [[ $ERR -eq 0 ]] ; then
      Plog "Now compiling all JPOs"
      $MQLCMD -d -t -c "set context user creator password $PSWD; compile prog * force" 2>> $LOGFILE
      ERR=$?
      if [[ $ERR -ne 0 ]] ; then
        Plog "  ### JPO Compile Failed! ###"
        return $ERR
     fi
   else
        Plog " ############## Spinner/MQL Error!! ##############"
        Plog " ############## Check Spinner log file!! #########"
        Plog "  NOT compiling JPOs"
        return $ERR
   fi
   Plog "SpinnerLoad completed with status $ERR"

   if [[ $ERR -eq 0 ]] ; then
      Plog "Now lets run some tcl scripts to do things the Spinners could not address"
      cd $SOURCEDIR/svn/tclScripts
      Plog "     fix source attribute"
      if [[ -a UpdateSourceAttributeRange.tcl ]] ; then
         $MQLCMD -d -t -c "set context user creator password $PSWD; run UpdateSourceAttributeRange.tcl" 2>> $LOGFILE
         ERR=$?
      fi
      #Keysight-ERI- Wizard not support in 17x
	  #Plog "     modify wizard"
      #if [[ -a Modify_Wizard_copy_exact.tcl ]] ; then
      #   $MQLCMD -d -t -c "set context user creator password $PSWD; run Modify_Wizard_copy_exact.tcl" 2>> $LOGFILE
      #   ERR=$?
      #fi
      # add more here

   else
        Plog " ############## Compile failure ##############"
        Plog "  NOT fixing what spinners broke"
        return $ERR
   fi
   Plog "Spinner repairs completed with status $ERR"
   if [[ $ERR -eq 0 ]] ; then
      Plog "Now updating  mail URLs"
      cd $SOURCEDIR/svn/systemfiles
      $MQLCMD -d -t -c "set context user creator password $PSWD; run Run_siteURL.tcl" 2>> $LOGFILE
      ERR=$?
      # remove once store and location templates are in place
      if [[ $ERR -eq 0 ]] ; then
         if [[ $ENV == "prod" ]]; then
           Plog "Repairing store and location paths with old script"
           $MQLCMD -d -t -c "set context user creator password $PSWD; run Run_stores_locs.tcl" 2>> $LOGFILE
           ERR=$?
         else
           Plog "NOT Repairing store and location paths"
         fi
      fi
   else
        Plog " ############## Spinner repair failure ##############"
        Plog "  NOT updating Stores and Locations"
        return $ERR
   fi
   return $ERR
}
############################################################################
# WarLoad
# loads the war file and exports
# Keysight-ERI - This Procedure is not used because war is generated using OOB script BuildDeploy3DSpace*sh.
############################################################################
WarLoad() {

   Plog "Now loading the war file"
   if [[ -a $SOURCEDIR/svn/ematrix/Build/ematrix.war ]]; then
      #$JAVA_HOME/bin/jar -xvf -C $SOURCEDIR/$M1_VER/server/STAGING/ematrix $SOURCEDIR/svn/ematrix/Build/ematrix.war
      $JAVA_HOME/bin/jar -xvf -C $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix $SOURCEDIR/svn/ematrix/Build/ematrix.war
   fi

   if [[ -a $SOURCEDIR/svn/ematrix/Build/schema.exp ]]; then
      Plog "Now loading the schema"
      CMD="trigger off; import admin * overwrite continue commit 1 from file schema.exp"
      $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE
      ERR=$?
   fi

   if [[ -a $SOURCEDIR/svn/ematrix/Build/Administration.exp  && $ERR -eq 0 ]]; then
      Plog "Now loading the Administration vault"
      CMD="import bus * * * overwrite continue commit 1 from file Administration.exp"
      $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE
      ERR=$?
   fi

   if [[ -a $SOURCEDIR/svn/ematrix/Build/tvcadmin.exp && $ERR -eq 0 ]]; then
      Plog "Now loading the TVC vault"
      CMD="import bus * * * overwrite continue commit 1 from file tvcadmin.exp"
      $MQLCMD -d -t -c "set context user creator password $PSWD; $CMD" 2>> $LOGFILE
      ERR=$?
   fi
   if [[ $ERR -ne 0 ]]; then
     Plog "    Imports failed"
   fi
}

############################################################################
# SVNCheckout
# loads the svn staging area from SVN
# 03/08/2018 Vijay Noble - RM:1766 - Replaced SVN URL http://tcssvn.cos.is.keysight.com with http://cossvn.is.keysight.com
#Keysight-ERI: Modified support script dir support to support17x
############################################################################
SVNCheckout() {
 if [[ $BRANCH != "" && $SVNUSER != "" && $SVNPWD != "" ]]; then
   #first lets start with a clean staging area
   if [[ -d $SOURCEDIR/svn ]]; then
     /bin/rm -rf $SOURCEDIR/svn/* 2>>$LOGFILE
   else
     /bin/mkdir $SOURCEDIR/svn 2>>$LOGFILE
   fi

   Plog "Now checking out everything from the branch $BRANCH to the directory $SOURCEDIR/svn."
   #specify specific trees since all may not be wanted

   $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH/ematrix $SOURCEDIR/svn/ematrix 2>> $LOGFILE
   ERR=$?
   if [[ $ERR -eq 0 ]]; then
     $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH/Spinner $SOURCEDIR/svn/Spinner 2>> $LOGFILE
     ERR=$?
   fi
   if [[ $ERR -eq 0 ]]; then
     $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH/apache $SOURCEDIR/svn/apache 2>> $LOGFILE
     ERR=$?
   fi
   if [[ $ERR -eq 0 ]]; then
     $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH/tclScripts $SOURCEDIR/svn/tclScripts 2>> $LOGFILE
     ERR=$?
   fi
   if [[ $ERR -eq 0 ]]; then
     $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/support17x/reports $SOURCEDIR/svn/reports 2>> $LOGFILE
     ERR=$?
   fi
    if [[ $ERR -eq 0 ]]; then
     $SVNCMD export -q --force --non-interactive --username $SVNUSER --password $SVNPWD http://cossvn.is.keysight.com/svn/MatrixOne/support17x/support_team_files $SOURCEDIR/svn/support_team_files 2>> $LOGFILE
     ERR=$?
   fi
   if [[ $ERR -ne 0 ]]; then
     Plog "    SVN Checkout failed"
   fi
 else
    Plog "SVN information not specified; nothing checked out from SVN"
 fi
 return $ERR
}

############################################################################
# Systemfiles
# generates system files and moves into place
############################################################################
Systemfiles() {
 Plog "Now updating SystemFiles"
 $TOOLDIR/sysfiles.sh $ENV $SVNUSER $SVNPWD 1 >> $LOGFILE 2>&1
 ERR=$?
 Plog "  SystemFile update finished with status $ERR"
return $ERR
}

############################################################################
# Makewar
# runs the war build script and moves files into place on all servers
# bouncing the servers.
#Keysight-ERI: Generating war for all the instance and move to its servers
############################################################################
Makewar() {
 #if [[ $ENV == "3dinteg" ]]; then
   Plog "Now backup the war and static files"
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.war_prev
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.ear_prev
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace_static.zip_prev
   
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_NoCAS/internal.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/internal.war_prev
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_NoCAS/internal.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/internal.ear_prev
   cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_NoCAS/internal_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/internal_static.zip_prev

   Plog "Now creating the war and static files"
   $SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_NoCAS.sh >> $LOGFILE 2>&1
   if [[ $ERR -eq 0 ]]; then
     cp $SOURCEDIR/$X3D_VER/3dspace/server/logs/ematrixwar.log $SOURCEDIR/$X3D_VER/3dspace/server/logs/ematrixwar_NoCAS.log
     $SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh >> $LOGFILE 2>&1
   fi
   Plog "***YOU MUST CHECK THE $SOURCEDIR/$X3D_VER/3dspace/server/logs/ematrixwar.log FOR ERRORS!***"
   
   #now lets copy files app servers
   if [[ $ENV == "3dbst" ]]; then
      TARGET=mxdap4.cos.is.keysight.com
	  Plog "Now copy files to mxdap4"
	    #lets move the files
	    scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		
		#lets move the war
		ssh $TARGET -C "rm -rf $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/*"
		scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
		scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
		scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
   fi
   if [[ $ENV == "prod" ]]; then
      TARGET=mxpap4.cos.is.keysight.com
	  TARGET1=mxpap5.cos.is.keysight.com
	  Plog "Now copy files to mxpap4"
	  #lets move the files
	  scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
	  rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
	  
	  #lets move the war to pap4
	  ssh $TARGET -C "rm -rf $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/*"
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	  
	  #Pap5
	  Plog "Now copy files to mxpap5"
	  scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
	  rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
	  
	  #lets move the war to pap5
	  ssh $TARGET1 -C "rm -rf $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/*"
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	  scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
   fi
   
   #now lets do external/dmz
   if [[ $ENV == "3dbst" ]]; then
      TARGET=mxdecos4.cos.dmz.keysight.com
	  #lets take backup
	  Plog "Now backup the war and static files in mxdecos4"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.war_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.ear_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace_static.zip_prev"
      if [[ $ERR -eq 0 ]]; then
	    #lets move the files
	    scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		
		#lets build the war
		Plog "Now creating the war and static files in mxdecos4"
	    ssh $TARGET -C "$SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh >> $LOGFILE 2>&1"
	  fi
   fi
   #now lets do prod dmz
   if [[ $ENV == "prod" ]]; then
      TARGET=mxpecos7.cos.dmz.keysight.com
	  TARGET1=mxpecos8.cos.dmz.keysight.com
	  #lets take backup
	  Plog "Now backup the war and static files in mxpecos7"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.war_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.ear_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace_static.zip_prev"
      if [[ $ERR -eq 0 ]]; then
	    #lets move the files
	    scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		
		#lets build the war
		Plog "Now creating the war and static files in mxpecos7"
	    ssh $TARGET -C "$SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh >> $LOGFILE 2>&1"
		
		if [[ $ERR -eq 0 ]]; then
		  Plog "Now copy the war and static files to mxpecos8"
		  #lets move the files
	      scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace
		  scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		  rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
	      scp -pr "$SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/*" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		  #lets copy external war to sup2 from pecos7
		  scp $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz
		  scp $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz
		  scp $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz
		  if [[ $ERR -eq 0 ]]; then
		     #lets move the war to pecos8
			 ssh $TARGET1 -C "rm -rf $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/*"
			 scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz/3dspace.war" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	         scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz/3dspace_static.zip" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
	         scp -p "$SOURCEDIR/$X3D_VER/3dspace/server/distrib_dmz/3dspace.ear" $USER@$TARGET1:$SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/
		  fi
		fi
	  fi
   fi

   #now lets do DR internal
   if [[ $ENV == "prod" ]]; then
      TARGET=mxdrap1.dfw.is.keysight.com
	  #lets take backup
	  Plog "Now backup the war and static files in mxdrap1"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.war_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.ear_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace_static.zip_prev"
      if [[ $ERR -eq 0 ]]; then
	    #lets move the files
	    scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		#lets build the war
		Plog "Now creating the war and static files in mxdrap1"
	    ssh $TARGET -C "$SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_NoCAS.sh >> $LOGFILE 2>&1"
		if [[ $ERR -eq 0 ]]; then
            ssh $TARGET -C "$SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh >> $LOGFILE 2>&1"
         fi
	  fi
   fi
   #now lets do DR DMZ
   if [[ $ENV == "prod" ]]; then
      TARGET=mxpedr2.dfw.dmz.keysight.com
	  #lets take backup
	  Plog "Now backup the war and static files in mxpedr2"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.war $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.war_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace.ear $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace.ear_prev"
      ssh $TARGET -C "cp $SOURCEDIR/$X3D_VER/3dspace/server/distrib_CAS/3dspace_static.zip $SOURCEDIR/$X3D_VER/3dspace/server/distrib_prev/3dspace_static.zip_prev"
      if [[ $ERR -eq 0 ]]; then
	    #lets move the files
	    scp -pr $SOURCEDIR/svn/ematrix/server $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace
	    scp -pr "$SOURCEDIR/svn/ematrix/server/STAGING/ematrix/properties/*" $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/classes
		rsync -avz --delete $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/classes $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/WEB-INF/lib
		scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/classes/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/docs/javaserver
	    scp -pr $SOURCEDIR/svn/ematrix/server/STAGING/ematrix/webapps/* $USER@$TARGET:$SOURCEDIR/$X3D_VER/3dspace/server/linux_a64/webapps
		#lets build the war
		Plog "Now creating the war and static files in mxpedr2"
	    ssh $TARGET -C "$SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh >> $LOGFILE 2>&1"
	  fi
   fi
   
   
   #Plog "Now moving the war and static files for integ"
 #  $TOOLDIR/matrix_manage.sh moveonly $ENV  >> $LOGFILE 2>&1

# elif [[ $ENV == "3dbst" ]]; then
#  # first lets modify some files for bst
#  Plog "Modifying the web.xml file for v6bst"
#  $SEDCMD 's/v6bst/prod/' $SOURCEDIR/$M1_VER/server/STAGING/ematrix/WEB-INF/web.xml > $SOURCEDIR/$M1_VER/server/ematrixwarutil/tmpfile
#  $MVCMD $SOURCEDIR/$M1_VER/server/ematrixwarutil/tmpfile $SOURCEDIR/$M1_VER/server/STAGING/ematrix/WEB-INF/web.xml
#  
#  #now lets do external
#  if [[ -d $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external ]]; then
#     Plog "Modifying Ag_Custom.properties, Ag_emxJagLoginInclude.jsp, and emxLogin.properties for external war file for v6bst"
#     $CPCMD $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/properties/Ag_Custom.properties $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes
#     $CPCMD $SOURCEDIR/$X3D_VER/3dspace/server/STAGING/ematrix/Ag_emxJagLoginInclude.jsp $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external
#
#     $SEDCMD 's/= Indexed/= Real Time/' $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes/Ag_Custom.properties > $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes/tmpfile
#     $SEDCMD 's/emxLogin.viewAgreement=false/emxLogin.viewAgreement=true/' $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes/tmpfile > $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes/Ag_Custom.properties
#     $RMCMD $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/WEB-INF/classes/tmpfile
#	  #Modified for Redmine - 779 - Changed the alias for External supply chain
#     $SEDCMD 's/http:\/\/enoviaportal.cos.is.keysight.com:8080/https:\/\/us.supplychain.keysight.com/' $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/Ag_emxJagLoginInclude.jsp > $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/tmpfile
#     # Modified for Redmine-484
#	  #$SEDCMD 's/http:\/\/wps.service.agilent.com\/global_trade\/policy_stmt.htm/http:\/\/gtt.agilent.com\/trade\/exportadmin\/letter.pdf/' $SOURCEDIR/$X3D_VER/server/distrib/external/tmpfile > $SOURCEDIR/$X3D_VER/server/distrib/external/Ag_emxJagLoginInclude.jsp
#	  # Modified for Redmine-851
#	  #$SEDCMD '/http:\/\/wps.service.keysight.com\/global_trade\/policy_stmt.htm/d' $SOURCEDIR/$X3D_VER/server/distrib/external/tmpfile > $SOURCEDIR/$X3D_VER/server/distrib/external/Ag_emxJagLoginInclude.jsp
#	  #$SEDCMD '/http:\/\/wps.service.agilent.com\/global_trade\/policy_stmt.htm/d' $SOURCEDIR/$X3D_VER/server/distrib/external/tmpfile > $SOURCEDIR/$X3D_VER/server/distrib/external/Ag_emxJagLoginInclude.jsp
#	  $SEDCMD '/http:\/\/gtl.supplychain.keysight.com\/global_trade\/policy_stmt.htm/d' $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/tmpfile > $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/Ag_emxJagLoginInclude.jsp
#     $RMCMD $SOURCEDIR/$X3D_VER/3dspace/server/distrib/external/tmpfile
#  fi
#  Plog "Now creating the internal and external war and static files for v6bst"
# # $SOURCEDIR/$X3D_VER/3dspace/server/ematrixwarutil/ag_war_setup.sh auto >> $LOGFILE 2>&1
#  $SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_CAS.sh  >> $LOGFILE 2>&1
#  $SOURCEDIR/$X3D_VER/3dspace/server/scripts/BuildDeploy3DSpace_NoCAS.sh  >> $LOGFILE 2>&1
   
   #Plog "***YOU MUST CHECK THE ematrixwar.log FOR ERRORS!***"

   #Plog "Now moving the war and static files for v6bst, will take some time..."
 #  $TOOLDIR/matrix_manage.sh moveonly $ENV  >> $LOGFILE 2>&1
   #plog "Move of the war and static files for v6bst completed"
 #fi
}

############################################################################
# UpdateAllSystemfiles
# Updates systemfiles for all instances of an environment
# 1 = dont do local box as already done earlier in this script
# Keysight-ERI: Generating system files for all the instance.
############################################################################
UpdateAllSystemfiles() {
   #if [[ $ENV == "3dinteg" || $ENV == "3dbst" || $ENV == "prod" ]]; then
      Plog "Now Updating Systemfiles on all instances for $ENV. This is the last step in the update process."
      Plog "If this fails you can just run Manage System Files to complete the update."
      $TOOLDIR/sysfile_manage.sh $ENV $SVNUSER $SVNPWD 1  >> $LOGFILE 2>&1
      Plog "Now bouncing all instances for $ENV"
      $TOOLDIR/matrix_manage.sh bounceall $ENV  >> $LOGFILE 2>&1
   #fi
}

############################################################################
# Tstop
# Stops the instance
# Keysight-ERI: Modified the script name.
############################################################################
Tstop() {
 Plog "Now stopping servers on $ENV"
 #$TOOLDIR/matrix_control.sh all_stop $ENV  >> $LOGFILE
 $TOOLDIR/x3d_control.sh all_stop $ENV  >> $LOGFILE
}

############################################################################
# Tstart
# Starts the instance
# Keysight-ERI: Modified the script name.
############################################################################
Tstart() {
 Plog "Now starting servers on $ENV"
 #$TOOLDIR/matrix_control.sh all_start $ENV  >> $LOGFILE
 $TOOLDIR/x3d_control.sh all_start $ENV  >> $LOGFILE
}

############################################################################
# Compile Webservice JPOs
# Keysight-ERI: Modified the script name.
############################################################################
CompileWSJPO() {
      Plog "Now start Compiling Webservice JPO on $ENV"
      #cd $SOURCEDIR/svn/systemfiles
	  MQLCMD1=$SOURCEDIR/$X3D_VER/3dspace/server/scripts/mql
      $MQLCMD1 -d -t -c "set context user creator password $PSWD; run $SOURCEDIR/svn/systemfiles/CompileWSJpo.tcl" 2>> $LOGFILE
      ERR=$?
      if [[ $ERR -ne 0 ]] ; then
        Plog "  ### Webservices JPO Compile Failed! ###"
        #return $ERR
     fi
}


############################################################################
# CreateTag
# creates a tag copy under Tags based on date
# 03/08/2018 Vijay Noble - RM:1766 - Replaced SVN URL http://tcssvn.cos.is.keysight.com with http://cossvn.is.keysight.com 
# Keysight-ERI: Modified the instance name.
############################################################################
CreateTag() {
 ERR=0
 # Modified for RM#666, Create Tag for all the Branch
 #if [[ ($ENV == "integ" && $BRANCH == "Trunk") || $ENV == "v6bst" || $ENV == "prod" ]]; then
 if [[ ($ENV == "3dinteg" ) || $ENV == "3dbst" || $ENV == "prod" ]]; then
   TAG=`date +%b%d%y'_'%H%M`

   if [[ $ENV == "3dinteg" ]]; then
      Plog "Now creating an Integ Tag for this build"
      $SVNCMD copy -q --force-log --non-interactive --username $SVNUSER --password $SVNPWD \
              http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH \
               http://cossvn.is.keysight.com/svn/MatrixOne/tags/3dinteg_$TAG \
               -m "Automatically created from $BRANCH on `date`" 2>> $LOGFILE
       ERR=$?
       if [[ $ERR -eq 0 ]]; then
         Plog "  Tag: tags/3dinteg_$TAG created."
       else
         Plog "  Tag: tags/3dinteg_$TAG creation FAILED!"
       fi
   elif [[ $ENV == "3dbst" ]]; then
    Plog "Now creating a BST Tag for this build"
      $SVNCMD copy -q --force-log --non-interactive --username $SVNUSER --password $SVNPWD \
               http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH \
               http://cossvn.is.keysight.com/svn/MatrixOne/tags/3dbst_$TAG \
               -m "Automatically created from $BRANCH on `date`" 2>> $LOGFILE
       ERR=$?
       if [[ $ERR -eq 0 ]]; then
         Plog "  Tag: tags/3dbst_$TAG created."
       else
         Plog "  Tag: tags/3dbst_$TAG creation FAILED!"
       fi
   elif [[ $ENV == "prod" ]]; then
     Plog "Now creating a Production Tag for this build"
       $SVNCMD copy -q --force-log --non-interactive --username $SVNUSER --password $SVNPWD \
               http://cossvn.is.keysight.com/svn/MatrixOne/$BRANCH \
               http://cossvn.is.keysight.com/svn/MatrixOne/tags/Prod_$TAG \
               -m "Automatically created from $BRANCH on `date`" 2>> $LOGFILE
       ERR=$?
       if [[ $ERR -eq 0 ]]; then
         Plog "  Tag: tags/Prod_$TAG created."
       else
         Plog "  Tag: tags/Prod_$TAG creation FAILED!"
       fi
   fi
 fi
 return $ERR
}

############################################################################
# Main
############################################################################
# lets do some initial tests
if (($# < 6)); then
  print "Wrong number of Arguments"
  Usage
  exit
fi

if [[ $ENV != $DIR ]]; then
  print "Error: Environment not configured for SVN downloads."
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
  1)   	Plog "Starting the SVN download process to instance $ENV for Option $OPT"
         SVNCheckout
         if [[ $ERR -eq 0 ]]; then
               Tstop
  			   TreeLoad
  			   Systemfiles
  			   Tstart
  			   if [[ $ERR -eq 0 ]]; then
  			     SpinnerLoad
  			   fi
  			   if [[ $ERR -eq 0 ]]; then
  			     CreateTag
  		        if [[ $ERR -eq 0 ]]; then
  			       Makewar
  			       UpdateAllSystemfiles
				   CompileWSJPO
				   
 			     fi
 			   fi
   		fi
           ;;
  2)    	Plog "Starting the SVN download process to instance $ENV for Option $OPT"
         SVNCheckout
         if [[ $ERR -eq 0 ]]; then
  		      Tstop
  		      #WarLoad
  		      Tstart
  		   fi
           ;;
  3)     Plog "Just making war files and moving them, not restarting"
         Makewar
           ;;
  *)     print "Error: Unrecognized Option: $OPT"
         Usage
         exit
          ;;
esac
Plog "instanceUpdate.sh Finished at `date +%H:%M:%S` with status of $ERR"
Smail "Update with tag of $BRANCH finished for user $USR. Please check the log files on $ENV"
return $ERR
