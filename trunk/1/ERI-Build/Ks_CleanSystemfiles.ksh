#!/bin/ksh
################################################################################
# File:         Ks_CleanSystemfiles.ksh
#               
# Description:  Clear the files from svn/systemfiles directory
#              
# Environment:  Enovia V6
#
# Author:       Sharmila T C
# Created:      11/13/2014
#	
# Language:     KSH
# Package:      FIREDAM Support
# Status:       Internal Use Only
#
#               Clear SVN systemfiles
#   02.02.2019 - Vijay NOble- Keysight-ERI - Modified the instance names
# (c) Copyright 2014, Keysight Technologies, all rights reserved.
############################################################################

#####################################################################
# DIR_USER= env dir name|env user
#####################################################################

DIR_USER="3dvan|mxvan\n
			3dfulldev|mxfulld\n
			3ddev|mxdev\n
			3dbst|mxbst\n
			3dinteg|mxinteg\n
			prod|apache\n
			"

###################################################################
# Environment declarations
###################################################################

PRG=$0
ENV=$1
USR=$(whoami)

DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
MSGDISTLIST="pdl-enovia-enterprise-support@keysight.com"
SYSTEMFILES="/opt/matrixone/$ENV/svn/systemfiles"
errorlog="/opt/matrixone/$ENV/logs/svn/Ks_CleanSystemfiles.err"


############################################################################
# Usage
############################################################################
#| awk -F "\n" '{print $1}'
Usage() {
		INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
		INSTANCES=`echo $INSTANCES`
		echo "Usage: $PRG <environment>"
		echo
		echo "       Environments = $INSTANCES"
		echo
		}


############################################################################
# main
############################################################################

if (($# < 1)); then
	Usage
	exit
fi

if [[ "$DIR" != "$ENV" ]]; then
	echo "Error: Unrecognized environment: $ENV"
	Usage
	exit
fi

if [[ $USR != "root" && $USR != $USER ]]; then
	echo "Error: You must be root or the environment owner to run this script.\n"
	exit
fi

# Remove systemfiles on local server
echo "Now removing SVN systemfiles $ENV on ($(hostname))"
find $SYSTEMFILES -depth -mindepth 1 -exec rm -fr {} \; 2>> $errorlog

if [ -s $errorlog ]; then
	message="Ks_CleanSystemfiles.ksh script has errors, please review the message"
	print "`cat $errorlog`" | mail -s "$message ($(hostname))" $MSGDISTLIST
fi

echo "Removed SVN systemfiles $ENV on ($(hostname))"
