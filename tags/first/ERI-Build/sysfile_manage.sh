#!/bin/ksh
############################################################################
#
# sysfile_manage.sh - Script will run the SVN sysfiles.sh script on local
#                    box and any remote boxes for the instance
#                    the environment user must have ssh access on the remote boxes
# Author : Ric Schug
# Date :   Mar 12, 2011
#
# Change History:
#
#   3.12.2011 - Initial Revision
#   4.15.2014 - Updated with FQDN's for Test/dev servers
#
# 	Modified 04/29/2014 : Sarasugi
#						1) Updated with FQDN's for Dev/Prod servers
#
# 	Modified 05/15/2014 : Sarasugi
#						1) Updated with FQDN's for mxdecos1 and mxdecos2
#
# 	Modified 07/04/2014 : Sarasugi
#						1)Replaced Edinburgh old server name with new server name - mxpfsqf1.edi.is.keysight.com
#
# 	Modified 08/06/2014 : Sarasugi
#						1)Replaced Santa Clara old server name with new server name - mxpfscl1.scs.is.keysight.com
#
#   Modified 08/22/2014 : Sarasugi
#						1) Renamed the old DR box name with new DR box name - mxdrpap1k.dfw.is.keysight.com, mxpedr1k.dfw.keysight.com, mxpedr2k.dfw.keysight.com
#
# 	Modified 08/29/2014 : Sarasugi
#						1) Replaced Agilent FQDN's with Keysight FQDN's for prod servers
#
#	Modified 09/11/2014 : Sarasugi
#						1) Replaced Santa Rosa old server name with new server name	- mxpfsco1.srs.is.keysight.com
#	
#   Modified 09/17/2014 : Sarasugi
#						1) Replaced Singapore old server name with new server name	- mxpfsgp1.sgp.is.keysight.com
#
#	Modified 10/09/2014 : Sarasugi
#						1) Replaced ITAR box old server name with new server name	- mxpfitar1.lov.is.keysight.com
#
#	Modified 10/09/2014 : Sarasugi
#						1) Replaced Boeblingen old server name with new server name	- mxdfcs3.bbn.is.keysight.com, mxpfbbn1.bbn.is.keysight.com
#	Modified 10/31/2014 : Sharmila
#							Renamed ITAR file server name - mxpflov1.lov.is.keysight.com
#	Modified 10/09/2014 : Sarasugi
#						1) Replaced Penang old server name with new server name	- mxpfpng1.png.is.keysight.com
#	Modified 10/05/2015 : Vijay Noble
#						1) Updating System Files for instance prod on mxpedr1k.dfw.keysight.com and mxpedr2k.dfw.keysight.com
#                       2) Added DEST17 and DEST18
#	Modified 03/16/2018 : Vijay Noble
#						1) Added mxdfcs1.cos.is.keysight.com to v6dev instance (Line 75).
#	Modified 03/01/2019 : Vijay Noble
#						1) Modified server names for Keysight-ERI.
############################################################################
###################################################################
# Environment declarations
###################################################################

#####################################################################
# make changes/additions for environments to the DIR_USER
# variable. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
# DIR_USER= env dir name|env user|machine|instance count
#####################################################################
#Keysight-ERI -START
DIR_USER="3dbst|mxbst|mxdap3|6\n
          3dinteg|mxinteg|mxdap4|3\n
          3ddev|mxdev|mxdap3|3\n
          3dfulldev|mxfulld|mxdap4|3\n
          prod|apache|mxpsup2|15\n
         "
DEST="3dbst|mxdap4.cos.is.keysight.com|mxdfcs4.cos.is.keysight.com|mxdecos4.cos.dmz.keysight.com|mxdfcs6.bbn.is.keysight.com|mxdpass5.cos.is.keysight.com|mxddash5.cos.is.keysight.com\n
      3dinteg|mxdfcs5.cos.is.keysight.com|mxdpass3.cos.is.keysight.com|mxddash3.cos.is.keysight.com\n
      3ddev|mxdfcs4.cos.is.keysight.com|mxdpass2.cos.is.keysight.com|mxddash2.cos.is.keysight.com\n
      3dfulldev|mxdfcs5.cos.is.keysight.com|mxdpass4.cos.is.keysight.com|mxddash4.cos.is.keysight.com\n
      prod|mxpap4.cos.is.keysight.com|mxpap5.cos.is.keysight.com|mxpfcol2.cos.is.keysight.com|mxpfbbn2.bbn.is.keysight.com|mxpfhch2.hch.is.keysight.com|mxpflov3.lov.is.keysight.com|mxpfpng2.png.is.keysight.com|mxpfscl2.scs.is.keysight.com|mxpfsrs2.srs.is.keysight.com|mxpfsgp2.sgp.is.keysight.com|mxpfedi2.edi.is.keysight.com|mxpecos7.cos.dmz.keysight.com|mxpecos8.cos.dmz.keysight.com|mxdrap1.dfw.is.keysight.com|mxpedr2.dfw.dmz.keysight.com\n
     "
#Keysight-ERI -END
PRG=$0
ENV=$1
SVNUSER=$2
SVNPWD=$3
DOLOC=$4
USR=$(whoami)
NODE=$(uname -n)
TOOL_HOME=/opt/matrixone/tools/mms

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
SOURCE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
integer inst_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`


DEST1=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
DEST2=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
DEST3=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
DEST4=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
DEST5=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
DEST6=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`
DEST7=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $8}'`
DEST8=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $9}'`
DEST9=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $10}'`
DEST10=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $11}'`
DEST11=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $12}'`
DEST12=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $13}'`
DEST13=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $14}'`
DEST14=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $15}'`
DEST15=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $16}'`
DEST16=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $17}'`
DEST17=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $18}'`
DEST18=`echo -e $DEST | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $19}'`
############################################################################
# Usage
############################################################################

Usage() {
 INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
 INSTANCES=`echo $INSTANCES`
 print "Usage: $PRG <environment> <SVN User> <SVN Password> <local>"
 print
 print "             This script will run the sysfiles.sh script to update all SystemFiles from SVN"
 print "             and move them into place. The environment will be updated on both local and"
 print "             remote boxes. You must be the instance owner to run this script and the"
 print "             owner must have ssh access on all remote boxes."
 print
 print "       OPTIONAL: local - 1 skips local box"
 print
 print "       Environments: $INSTANCES"
}

############################################################################
# main
############################################################################
# first lets do some tests
if (($# < 3)); then
  Usage
  exit
fi

if [[ $SOURCE != $NODE ]]; then
  print "\nError: You must be on the machine $SOURCE to run this script.\n"
  exit
fi

if [[ "$DIR" != "$ENV" ]]; then
  print "\nError: Unrecognized environment: $ENV"
  Usage
  exit
fi

if [[ $USR != $USER ]]; then
  print "\nError: You must be the environment owner to run this script.\n"
  exit
fi

# first lets update the local box
if [[ $DOLOC -ne 1 ]] ; then
  print "\nFirst lets update the System Files for instance $DIR on $SOURCE."
  $TOOL_HOME/sysfiles.sh $ENV $SVNUSER $SVNPWD 1
fi

#now lets to the remote boxes
   if (( inst_num > 0 ))
		then
			integer count=1
			while (( count <= inst_num ))
			do
	  			TARGET=$(eval print '$DEST'$count)
				print "\nUpdating System Files for instance $DIR on $TARGET"
	   		ssh $USER@$TARGET "$TOOL_HOME/sysfiles.sh $ENV $SVNUSER $SVNPWD 1"
	   		(( count = count + 1))
			done
	 else
			print "No remote instances to update"
	fi

print "\nFINISHED!"
return 0
