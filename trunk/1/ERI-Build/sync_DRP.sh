#!/bin/ksh
###################################################################################
#
# sync_DRP.sh - Script for sync Enovia DR instance support, plm bridge script, 
#               portal with support instance.
#               This script requires the authorized_keys to be set up on DR boxes 
#               so that scp and ssh can be run with no prompts.
#               This script assumes a push from the source machine-mxpsup2.
#
# Author : Vijay Noble
# Date :   Oct 1, 2015
#
# Change History:
#
#   01.10.2015 - Initial Revision- Redmine 1184
#   14.10.2015 - Added code to copy the external portal mastered on mxpsup2 to 
#                mepcos1/2 external servers
#   02.02.2019 - Vijay Noble- Keysight-ERI: Modified the server names
#   29.05.2019 - Vijay Noble- Keysight-ERI: Commented EEDP Sync command.
#   04.09.2019 - Scott Ferguson - Keysight-ERI: Updated portal directory names
###################################################################################
# Environment declarations
###################################################################################
PRG=$0
ENV=$1
USR=$(whoami)
NODE=$(uname -n)

# Destination DR Servers
DESTDRP="mxdrap1.dfw.is.keysight.com"
DESTDREXT="mxpedr2.dfw.dmz.keysight.com"

DESTEXT1="mxpecos7.cos.dmz.keysight.com"
DESTEXT2="mxpecos8.cos.dmz.keysight.com"

ENV_HOME=/opt/matrixone/$ENV
APACHE_HOME=/home/matrixusers/apache/
EEDP_HOME=/home/matrixusers/eedp/
DOC_ROOT=/opt/matrixone/prod/apache/docroot

############################################################################
# Usage
############################################################################
Usage() {
 print "Usage: $PRG <environment>"
 print
 print "  This script will sync DR & external instances apache, plm bridge scripts, & portal directories with mxpsup2 instance"
 print
 print "  Environment: prod"
}

############################################################################
# main
############################################################################
# First Check the parameter passed
if (($# < 1)); then
  Usage
  exit
fi

# Allow only apache user to execute the script.
if [[ $USR != "apache" ]]; then
  print
  print "Error: You must be user apache to run this script.\n"
  exit
fi

# Script should be executed from mxpsup2 only.
if [[ $NODE != "mxpsup2" ]]; then
  print
  print "Error: You must run the script from mxpsup2.cos.is.keysight.com\n"
  exit
fi

# Remove the existing log file.
if [[ -f /tmp/DRPrsync_results ]] ; then
       rm /tmp/DRPrsync_results
fi

print
print "rsync started..."

#############################################################################
################### Sync DRP instance #######################################
#############################################################################

    #################### Sync apache dir ########################### 
    print "\n  Sync apache dir to $DESTDRP"
    #rsync -avz --delete $APACHE_HOME $USR@$DESTDRP:$APACHE_HOME/ >> /tmp/DRPrsync_results 2>&1
    	rsync -avz --delete $APACHE_HOME/support_team_files $USR@$DESTDRP:$APACHE_HOME/ >> /tmp/DRPrsync_results 2>&1
	rsync -avz --delete $APACHE_HOME/crontab* $USR@$DESTDRP:$APACHE_HOME/ >> /tmp/DRPrsync_results 2>&1
	rsync -avz --delete $APACHE_HOME/*properties $USR@$DESTDRP:$APACHE_HOME/ >> /tmp/DRPrsync_results 2>&1
	rsync -avz --delete $APACHE_HOME/.cronprofile $USR@$DESTDRP:$APACHE_HOME/ >> /tmp/DRPrsync_results 2>&1

    #################### Sync eedp dir ############################## 
    #Keysight-ERI: 05/29 - Sync command is executed from mxsup2 eedp cron.
    #print "\n  Sync eedp dir to $DESTDRP"
    #rsync -avz --delete $EEDP_HOME eedp@$DESTDRP:$EEDP_HOME/ >> /tmp/DRPrsync_results 2>&1


    #################### Sync PLM Bridge Scripts #################### 
    print "\n  Sync PLM Bridge Scripts to $DESTDRP"
    rsync -avz --delete $ENV_HOME/reports/ $USR@$DESTDRP:$ENV_HOME/reports/ >> /tmp/DRPrsync_results 2>&1


    #################### Sync DRP Portal ############################
    print "\n  Sync Internal Portal files to $DESTDRP"
    rsync -avz --delete $DOC_ROOT/portal           $USR@$DESTDRP:$DOC_ROOT/ >> /tmp/DRPrsync_results 2>&1
    rsync -avz --delete $DOC_ROOT/portal_external  $USR@$DESTDRP:$DOC_ROOT/ >> /tmp/DRPrsync_results 2>&1
    rsync -avz --delete $DOC_ROOT/index.html       $USR@$DESTDRP:$DOC_ROOT/ >> /tmp/DRPrsync_results 2>&1
    rsync -avz --delete $DOC_ROOT/favicon.ico      $USR@$DESTDRP:$DOC_ROOT/ >> /tmp/DRPrsync_results 2>&1

    #############################################################################
    ################### Sync External DRP Portal Files ##########################
    #############################################################################

    #################### Sync DRP External Portal ###################### 
    print "\n  Sync External Portal files to $DESTDREXT"
  
    rsync -avz --delete $DOC_ROOT/portal_external/ $USR@$DESTDREXT:$DOC_ROOT/3dportal/ >> /tmp/DRPrsync_results 2>&1

#############################################################################
################### Sync External Portal Files ##############################
#############################################################################

    #################### Sync mxpecos7 External Portal #################### 
    print "\n  Sync External Portal files to $DESTEXT1"
    rsync -avz --delete $DOC_ROOT/portal_external/ $USR@$DESTEXT1:$DOC_ROOT/3dportal/ >> /tmp/DRPrsync_results 2>&1

    #################### Sync mxpecos8 External Portal #################### 
    print "\n  Sync External Portal files to $DESTEXT2"
    rsync -avz --delete $DOC_ROOT/portal_external/ $USR@$DESTEXT2:$DOC_ROOT/3dportal/ >> /tmp/DRPrsync_results 2>&1

##########################################################################################
#################################### Done ################################################
##########################################################################################
print
print "Done with rsync..."
print
