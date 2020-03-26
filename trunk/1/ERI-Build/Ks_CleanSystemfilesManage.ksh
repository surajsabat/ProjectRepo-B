#!/bin/ksh
############################################################################
#
# File:			Ks_CleanSystemfilesManage.ksh
# Description:	Script for clearing the SVN systemfiles on local server and all other boxes
#				this script requires the authoried_keys to be set up on all
# 				boxes so that scp and ssh can be run with no prompts.
#           
# Environment:  Enovia V6
# Author:		Sharmila T C
# Created:		11/13/2014
#	
# Language:		KSH
# Package:      FIREDAM Support
# Status:       Internal Use Only
#
#				Clean systemfiles
#
# (c) Copyright 2014, Keysight Technologies, all rights reserved.
# 03/04/2019 Vijay Noble - Keysight-ERI- Modified the server names
############################################################################
#####################################################################
#
# DIR_USER=env dir name|env user|source instance|#no of internal nodes|# of external nodes
# INSTANCES=env dir name|server name|
# EXTINSTANCES=env dir name|server name|

#####################################################################

DIR_USER="3ddev|mxdev|mxdap3|3|0\n
			3dbst|mxbst|mxdap3|6|0\n
			3dinteg|mxinteg|mxdap4|3|0\n
			3dfulldev|mxfulld|mxdap4|3|0\n
			prod|apache|mxpsup2|15|0\n
			"
			
INSTANCES="3ddev|mxdfcs4.cos.is.keysight.com|mxdpass2.cos.is.keysight.com|mxddash2.cos.is.keysight.com\n
			3dbst|mxdap4.cos.is.keysight.com|mxdfcs4.cos.is.keysight.com|mxdecos4.cos.dmz.keysight.com|mxdfcs6.bbn.is.keysight.com|mxdpass5.cos.is.keysight.com|mxddash5.cos.is.keysight.com\n
			3dinteg|mxdfcs5.cos.is.keysight.com|mxdpass3.cos.is.keysight.com|mxddash3.cos.is.keysight.com\n
			3dfulldev|mxdfcs5.cos.is.keysight.com|mxdpass4.cos.is.keysight.com|mxddash4.cos.is.keysight.com\n
			prod|mxpap4.cos.is.keysight.com|mxpap5.cos.is.keysight.com|mxpfcol2.cos.is.keysight.com|mxpfbbn2.bbn.is.keysight.com|mxpfhch2.hch.is.keysight.com|mxpflov3.lov.is.keysight.com|mxpfpng2.png.is.keysight.com|mxpfscl2.scs.is.keysight.com|mxpfsrs2.srs.is.keysight.com|mxpfsgp2.sgp.is.keysight.com|mxpfedi2.edi.is.keysight.com|mxpecos7.cos.dmz.keysight.com|mxpecos8.cos.dmz.keysight.com|mxdrap1.dfw.is.keysight.com|mxpedr2.dfw.dmz.keysight.com\n
			"
EXTINSTANCES=""
#EXTINSTANCES="3dbst|mxdecos2.cos.is.keysight.com|mxdecos1.cos.keysight.com\n
#				prod|mxpecos1.cos.keysight.com|mxpecos2.cos.keysight.com|mxpecos3.cos.keysight.com|mxpecos4.cos.keysight.com\n
#				"

###################################################################
# Environment declarations
###################################################################

PRG=$0
ENV=$1
USR=$(whoami)
NODE=$(uname -n)
TOOLDIR=/opt/matrixone/tools/mms


DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
SOURCE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
integer instances_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
integer extinstances_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`


INSTANCE_DEST1=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
INSTANCE_DEST2=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
INSTANCE_DEST3=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
INSTANCE_DEST4=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
INSTANCE_DEST5=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
INSTANCE_DEST6=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`
INSTANCE_DEST7=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $8}'`
INSTANCE_DEST8=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $9}'`
INSTANCE_DEST9=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $10}'`
INSTANCE_DEST10=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $11}'`
INSTANCE_DEST11=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $12}'`
INSTANCE_DEST12=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $13}'`
INSTANCE_DEST13=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $14}'`
INSTANCE_DEST14=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $15}'`
INSTANCE_DEST15=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $16}'`
INSTANCE_DEST16=`echo -e $INSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $17}'`

EXTINSTANCE_DEST1=`echo -e $EXTINSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
EXTINSTANCE_DEST2=`echo -e $EXTINSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
EXTINSTANCE_DEST3=`echo -e $EXTINSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
EXTINSTANCE_DEST4=`echo -e $EXTINSTANCES | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`


############################################################################
# Usage
############################################################################

Usage() {
		INSTANCE=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
		INSTANCE=`echo $INSTANCE`
		echo "Usage: $PRG <environment>"
		echo "       Environments: $INSTANCE"
		echo
		}

############################################################################
# ClearAll
############################################################################

Clearall() {
if (( instances_num > 0 || extinstances_num > 0 )); then

	#Clear svn systemfiles on Source 
	$TOOLDIR/Ks_CleanSystemfiles.ksh $ENV


	integer count=1
	while (( count <= instances_num ))
	do
		TARGET=$(eval print '$INSTANCE_DEST'$count)
		ssh $TARGET -C "$TOOLDIR/Ks_CleanSystemfiles.ksh $ENV"
		(( count = count + 1))
	done
	
	integer count=1
	while (( count <= extinstances_num ))
	do
		TARGET=$(eval print '$EXTINSTANCE_DEST'$count)
		ssh $TARGET -C "$TOOLDIR/Ks_CleanSystemfiles.ksh $ENV"
		(( count = count + 1))
	done
else
	echo "No instances"
fi
}

############################################################################
# main
############################################################################
# lets do some tests
if (($# < 1)); then
	Usage
	exit
fi

if [[ $SOURCE != $NODE ]]; then
	echo "Error: You must be on the machine $SOURCE to run this script."
	exit
fi
if [[ "$DIR" != "$ENV" ]]; then
	echo "Error: Unrecognized environment: $ENV"
	Usage
	exit
fi

if [[ $USR != $USER ]]; then
	echo "Error: You must be the environment owner to run this script."
	exit
fi

Clearall

echo "FINISHED!"
return 0
