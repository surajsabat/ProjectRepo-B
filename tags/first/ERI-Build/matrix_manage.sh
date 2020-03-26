#!/bin/ksh
############################################################################
#
# matrix_manage.sh - Script for moving the war and static files to other boxes
#				this script requres the authoried_keys to be set up on all
# 				boxes so that scp and ssh can be run with no prompts.
#           This script assumes a push from the source machine.
#           This script can also be used to start and stop all instances.
# Author : Ric Schug
# Date :   Aug 2, 2007
#
# Change History:
#
#   8.02.2007 - Initial Revision
#   12.02.2007 - RAS - Added move to DRP box to moveall option
#							- Need to add mxptng1 when its up.
#   05.01.2010 - RAS - added external boxes to script
#    9.1.2010 - RAS - added integ instance
#    08.15.2012 - RAS - added iFrame move
#    4.13.2013 - RAS - updated for v6
#    4.15.2014 - Updated with FQDN's for Test/dev servers
#
# 	Modified 04/29/2014 : Thamarai
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
#   Modified 08/29/2014 : Sarasugi
#						1) Replaced Agilent FQDN's with Keysight FQDN's for prod servers
#
#	Modified 09/11/2014 : Sarasugi
#						1) Replaced Santa Rosa old server name with new server name	- mxpfsco1.srs.is.keysight.com
#
#	Modified 09/17/2014 : Sarasugi
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
#
#	Modified 10/15/2015 : Vijay Noble
#						1) Modified the newinfo.html location for external servers
#	Modified 03/01/2019 : Vijay Noble
#						1) Modified for Keysight-ERI
############################################################################
#####################################################################
# make changes/additions for environments to the DIR_USER, WAR, and STAT
# variables. No other edits should be needed.
#
# Assignment is pipe delimnted and as follows:
#
# DIR_USER= env dir name|env user|source instance|# of war nodes|# of apache nodes|# of external war |
#             # of external apaches
# WAR=env dir name|war target1|war target2
# STAT=env dir name|static target1|static target2
# EXTWAR=env dir name|war target1|war target2

#
# NOTE: each line must match for each varialbe!!!
# 	(i.e. line x in each variable must be for the same instance set)
#	(ex: line 1 is for BST, line 2 for Staging....
#####################################################################

#Keysight-ERI -START
DIR_USER="	3dinteg|mxinteg|mxdap4|3|0|0|0\n
			3ddev|mxdev|mxdap3|3|0|0|0\n
			3dfulldev|mxfulld|mxdap4|3|0|0|0\n
			3dbst|mxbst|mxdap3|5|0|1|0\n
			prod|apache|mxpsup2|13|0|2|0\n
         "
WAR=" 3ddev|mxdfcs4.cos.is.keysight.com|mxddash2.cos.is.keysight.com|mxdpass2.cos.is.keysight.com\n
	 3dinteg|mxdfcs5.cos.is.keysight.com|mxddash3.cos.is.keysight.com|mxdpass3.cos.is.keysight.com\n
	 3dfulldev|mxdfcs5.cos.is.keysight.com|mxddash4.cos.is.keysight.com|mxdpass4.cos.is.keysight.com\n
	 3dbst|mxdap4.cos.is.keysight.com|mxdfcs6.bbn.is.keysight.com|mxdfcs4.cos.is.keysight.com|mxddash5.cos.is.keysight.com|mxdpass5.cos.is.keysight.com\n
     prod|mxpap4.cos.is.keysight.com|mxpap5.cos.is.keysight.com|mxpfcol2.cos.is.keysight.com|mxpfbbn2.bbn.is.keysight.com|mxpfhch2.hch.is.keysight.com|mxpfpng2.png.is.keysight.com|mxpfscl2.scs.is.keysight.com|mxpfsrs2.srs.is.keysight.com|mxpfsgp2.sgp.is.keysight.com|mxpfedi2.edi.is.keysight.com|mxpflov3.lov.is.keysight.com|mxpdash1.cos.is.keysight.com|mxppass1.cos.is.keysight.com\n
    "
STAT="3dbst|mxdap4.cos.is.keysight.com\n
	   3dinteg|\n
		prod|mxpap4.cos.is.keysight.com|mxpap5.cos.is.keysight.com\n
     "
EXTWAR="3dbst|mxdecos4.cos.dmz.keysight.com\n
        prod|mxpecos7.cos.dmz.keysight.com|mxpecos8.cos.dmz.keysight.com\n
       "

EXTSTAT="3dbst|mxdecos4.cos.dmz.keysight.com\n
         prod|mxpecos7.cos.dmz.keysight.com|mxpecos8.cos.dmz.keysight.com\n
        "
#Keysight-ERI -END
###################################################################
# Environment declarations
###################################################################

PRG=$0
CMD=$1
ENV=$2
USR=$(whoami)
NODE=$(uname -n)
#RMI_VER=enovia_v6r2012x
X3D_VER=r2017x
#JDK_VER=jdk1.6.0_30
JDK_VER=latest
START=TRUE
TOOLDIR=/opt/matrixone/tools/mms

#NOTE RedHat 5 needs the -e in echo
DIR=`echo -e $DIR_USER | sed 's/^ //' |grep "^$ENV|" | awk -F '|' '{print $1}'`
USER=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
SOURCE=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
integer war_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
integer stat_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
integer extwar_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
integer extstat_num=`echo -e $DIR_USER | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`

WAR_DEST1=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
WAR_DEST2=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
WAR_DEST3=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`
WAR_DEST4=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $5}'`
WAR_DEST5=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $6}'`
WAR_DEST6=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $7}'`
WAR_DEST7=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $8}'`
WAR_DEST8=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $9}'`
WAR_DEST9=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $10}'`
WAR_DEST10=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $11}'`
WAR_DEST11=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $12}'`
WAR_DEST12=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $13}'`
WAR_DEST13=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $14}'`
WAR_DEST14=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $15}'`
WAR_DEST15=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $16}'`
WAR_DEST16=`echo -e $WAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $17}'`

STAT_DEST1=`echo -e $STAT | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
STAT_DEST2=`echo -e $STAT | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`
STAT_DEST3=`echo -e $STAT | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $4}'`


EXTWAR_DEST1=`echo -e $EXTWAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
EXTWAR_DEST2=`echo -e $EXTWAR | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`

EXTSTAT_DEST1=`echo -e $EXTSTAT | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $2}'`
EXTSTAT_DEST2=`echo -e $EXTSTAT | sed 's/^ //'|grep "^$ENV|" | awk -F '|' '{print $3}'`

DOCROOT_HOME=/opt/matrixone/$ENV/apache/docroot
#WAR_HOME=/opt/matrixone/$ENV/$RMI_VER/server/distrib
WAR_HOME=/opt/matrixone/$ENV/$X3D_VER/3dspace/server/distrib_CAS


############################################################################
# Usage
############################################################################

Usage() {
 INSTANCES=`echo -e $DIR_USER | awk -F "\n" '{print $1}' | awk -F "|" '{print $1}'`
 INSTANCES=`echo $INSTANCES`
 print "Usage: $PRG <command> <environment>"
 print
 print "       Commands: "
 print "                 movewar - move war file to all servers and restart"
 #print "                 movestatic - move static file to all apache servers and restart"
 #print "                 moveall - movewar and movestatic"
 print "                 moveonly - does a moveall but does NOT restart"
 print "                 moveiframe - copies the IFrame file to all locations"
 print "                              both internal and external are included"
 #print "                 movedrp - move war and static files to drp"
 print
 #print "                 startall - start all tomee and apache servers"
 #print "                 stopall - stop all tomee and apache servers"
 print "                 startall - start all tomee"
 print "                 stopall - stop all tomee"
 print "                 bounceall - stopall then startall"
 print
 print "       Environments: $INSTANCES"
 print
}

############################################################################
# Movewar
############################################################################

Movewar() {
	if (( war_num > 0 ))
     then
       if [[ $START == TRUE ]]
        then
        print "Now stopping All servers for $ENV on $SOURCE\n"
		$TOOLDIR/x3d_control.sh all_stop $ENV

		print "Now starting All servers for $ENV on $SOURCE\n"
		$TOOLDIR/x3d_control.sh all_start $ENV
      fi

		integer count=1
		while (( count <= war_num ))
		do
	 	  	TARGET=$(eval print '$WAR_DEST'$count)
	 	  	if [[ $START == TRUE ]]
            then
	 	    print "Now stopping Tomee on $TARGET"
			ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_stop $ENV"
			else
			    print "Not stopping Tomee on $TARGET\n"
            fi
			# Keysight-ERI -START
            if [[ "$ENV" == "prod" && "$TARGET" == "mxpap4.cos.is.keysight.com" ]]; then
			    print "\nCopying war file to $TARGET"
				ssh $TARGET -C "rm -rf $WAR_HOME/3dspace"
	  	 	    scp $WAR_HOME/3dspace.war $USER@$TARGET:$WAR_HOME
            fi
			if [[ "$ENV" == "prod" && "$TARGET" == "mxpap5.cos.is.keysight.com" ]]; then
			    print "\nCopying war file to $TARGET"
				ssh $TARGET -C "rm -rf $WAR_HOME/3dspace"
	  	 	    scp $WAR_HOME/3dspace.war $USER@$TARGET:$WAR_HOME
            fi
			if [[ "$ENV" == "3dbst" && "$TARGET" == "mxdap4.cos.is.keysight.com" ]]; then
			    print "\nCopying war file to $TARGET"
				ssh $TARGET -C "rm -rf $WAR_HOME/3dspace"
	  	 	    scp $WAR_HOME/3dspace.war $USER@$TARGET:$WAR_HOME
            fi
			# Keysight-ERI -END
         if [[ $START == TRUE ]]
           then
			   print "Now starting Tomee on $TARGET\n"
			    ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_start $ENV"
			  else
			    print "Not starting Tomee on $TARGET\n"
         fi
	   	(( count = count + 1))
		done
	else
		print "No Internal instances to move war file to"
	fi
   # now we need to do external war move
	if (( extwar_num > 0 ))
      then
		    integer count=1
		    while (( count <= extwar_num ))
		      do
		        TARGET=$(eval print '$EXTWAR_DEST'$count)
		        print "Now stopping Tomee on $TARGET"
			     ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_stop $ENV"
                 
			     print "\nCopying war file to $TARGET"
				 # Keysight-ERI -START
				 if [[ "$TARGET" == "mxpecos8.cos.dmz.keysight.com" ]]; then
			        print "\nCopying war file to $TARGET"
					#EXTSOURCE=mxpecos7.cos.dmz.keysight.com
					#Copy war file to mxpecos8
					#ssh $EXTSOURCE -C "scp $WAR_HOME/3dspace.war $USER@$TARGET:$WAR_HOME/"
					ssh $TARGET -C "rm -rf $WAR_HOME/3dspace"
					scp /opt/matrixone/$ENV/$X3D_VER/3dspace/server/distrib_dmz/3dspace.war $USER@$TARGET:$WAR_HOME
  		            #scp $WAR_HOME/external/3dspace.war $USER@$TARGET:$WAR_HOME
                 fi
				 # Keysight-ERI -END
	  	 	     

              if [[ $START == TRUE ]]
                then
			          print "Now starting Tomee on $TARGET"
			          ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_start $ENV"
			       else
			          print "NOT starting Tomee on $TARGET\n"
              fi
	   	    (( count = count + 1))
		    done
	  else
		 print "No External instances to move war file to"
	fi
}

############################################################################
# Movestatic
############################################################################

Movestatic() {
	if (( stat_num > 0 ))
		then
			integer count=1
			while (( count <= stat_num ))
			do
	  			TARGET=$(eval print '$STAT_DEST'$count)
				print "\nCopying static file to $TARGET"
	   		scp $WAR_HOME/3dspace_static.zip $USER@$TARGET:$DOCROOT_HOME

            if [[ $START == TRUE ]]
             then
				print "Now stopping Apache on $TARGET"
				ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_stop $ENV"
             else
			      print "NOT stopping Apache on $TARGET\n"
            fi
				print "Now unziping static content on $TARGET"
				ssh $TARGET -C "cd $DOCROOT_HOME; /opt/matrixone/$ENV/java/$JDK_VER/bin/jar -xvf 3dspace_static.zip"

            if [[ $START == TRUE ]]
             then
				   print "Now starting Apache on $TARGET\n"
				  ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_start $ENV"
				 else
			      print "NOT starting Apache on $TARGET\n"
            fi
	   		(( count = count + 1))
			done
		else
			print "No internal instances to move static file to"
	fi
   if (( extstat_num > 0 ))
		then
			integer count=1
			while (( count <= extstat_num ))
			do
	  			TARGET=$(eval print '$EXTSTAT_DEST'$count)
				print "\nCopying static file to $TARGET"
	   		scp $WAR_HOME/external/3dspace_static.zip $USER@$TARGET:$DOCROOT_HOME

            if [[ $START == TRUE ]]
             then
				print "Now stopping Apache on $TARGET"
				ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_stop $ENV"
				 else
			      print "NOT stopping Apache on $TARGET\n"
            fi
				print "Now unziping static content on $TARGET"
				ssh $TARGET -C "cd $DOCROOT_HOME; /opt/matrixone/$ENV/java/$JDK_VER/bin/jar -xvf 3dspace_static.zip"

            if [[ $START == TRUE ]]
             then
				   print "Now starting Apache on $TARGET\n"
				  ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_start $ENV"
				 else
			      print "NOT starting Apache on $TARGET\n"
            fi
	   		(( count = count + 1))
			done
	 else
			print "No external instances to move static file to"
	fi
}

############################################################################
# Stopall
############################################################################

Stopall() {
	if (( war_num > 0 || extwar_num > 0 )); then
	   # not stopping sup box due to global rollup running
	   if [[ "$ENV" != "prod" && "$NODE" != "mxpsup2" ]]; then
        print "Now stopping All servers for $ENV on $SOURCE\n"
		    $TOOLDIR/x3d_control.sh all_stop $ENV
      fi

		integer count=1
		while (( count <= war_num ))
		do
			TARGET=$(eval print '$WAR_DEST'$count)
			print "Now stopping All servers for $ENV on $TARGET\n"
			ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_stop $ENV"

	   	(( count = count + 1))
		done
		integer count=1
		while (( count <= extwar_num ))
		do
			TARGET=$(eval print '$EXTWAR_DEST'$count)
			print "Now stopping Tomee for $ENV on $TARGET\n"
			ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_stop $ENV"

	   	(( count = count + 1))
		done
		#integer count=1
		#while (( count <= extstat_num ))
		#do
		#	TARGET=$(eval print '$EXTSTAT_DEST'$count)
		#	print "Now stopping Apache for $ENV on $TARGET\n"
		#	ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_stop $ENV"
	   	#(( count = count + 1))
		#done
	else
		print "No instances to stop"
	fi
}

############################################################################
# Startall
############################################################################

Startall() {
	if (( war_num > 0 || extwar_num > 0 ))
     then
      if [[ "$ENV" != "prod" && "$NODE" != "mxpsup2" ]]; then
        print "Now starting All servers for $ENV on $SOURCE\n"
		    $TOOLDIR/x3d_control.sh all_start $ENV
      fi

		integer count=1
		while (( count <= war_num ))
		do
			TARGET=$(eval print '$WAR_DEST'$count)
			print "Now starting All servers for $ENV on $TARGET\n"
			ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_start $ENV"

	   	(( count = count + 1))
		done
		integer count=1
		while (( count <= extwar_num ))
		do
			TARGET=$(eval print '$EXTWAR_DEST'$count)
			print "Now starting Tomee for $ENV on $TARGET\n"
			ssh $TARGET -C "$TOOLDIR/x3d_control.sh all_start $ENV"

	   	(( count = count + 1))
		done
		#integer count=1
		#while (( count <= extstat_num ))
		#do
		#	TARGET=$(eval print '$EXTSTAT_DEST'$count)
		#	print "Now starting Apache for $ENV on $TARGET\n"
		#	ssh $TARGET -C "$TOOLDIR/x3d_control.sh apache_start $ENV"
	   	#(( count = count + 1))
		#done
	else
		print "No instances to start"
	fi
}

#############################################################################
# MoveIFrame
#############################################################################

MoveIFrame() {
    if [[ "$ENV" == "prod" && "$NODE" == "mxpsup2" ]]; then
       print "Copying IFrame files for $ENV"
 	    if (( stat_num > 0 )); then
			 integer count=1
			 while (( count <= stat_num ))
			    do
	  			    TARGET=$(eval print '$STAT_DEST'$count)
	  			    if [[ "$TARGET" != "mxpsup2" ]]; then
				         print "\nCopying newinfo.html file to $TARGET"
	   		        scp $DOCROOT_HOME/newinfo.html $USER@$TARGET:$DOCROOT_HOME
	   		    fi
	   		    (( count = count + 1))
			 done
		 else
	      print "No instances to move IFrame file to"
		 fi
	    if (( extstat_num > 0 )); then
			  integer count=1
			  while (( count <= extstat_num ))
			     do
	  			    TARGET=$(eval print '$EXTSTAT_DEST'$count)
	  			    if [[ "$TARGET" != "mxpsup2" ]]; then
				         print "\nCopying newinfo.html external file to $TARGET"
						 #Keysight Mod: 15/10/2015- Vijay : RM1184
						 #scp $DOCROOT_HOME/newinfo_ext.html $USER@$TARGET:$DOCROOT_HOME/newinfo.html
	   		             scp $DOCROOT_HOME/portal_external/newinfo.html $USER@$TARGET:$DOCROOT_HOME/newinfo.html
	   		    fi
	   		    (( count = count + 1))
			  done
	    else
	      print "No instances to move IFrame file to"
	    fi
    elif [[ "$ENV" == "bst" && "$NODE" == "mxdap1" ]]; then
       print "Copying IFrame files for $ENV"
 	    if (( stat_num > 0 )); then
			 integer count=1
			 while (( count <= stat_num ))
			    do
	  			    TARGET=$(eval print '$STAT_DEST'$count)
	  			    if [[ "$TARGET" != "mxdap1" ]]; then
				         print "\nCopying newinfo.html file to $TARGET"
	   		        scp $DOCROOT_HOME/newinfo.html $USER@$TARGET:$DOCROOT_HOME
	   		    fi
	   		    (( count = count + 1))
			 done
		 else
	      print "No instances to move IFrame file to"
	    fi
	    if (( extstat_num > 0 )); then
			  integer count=1
			  while (( count <= extstat_num ))
			     do
	  			    TARGET=$(eval print '$EXTSTAT_DEST'$count)
	  			    if [[ "$TARGET" != "mxdap1" ]]; then
				         print "\nCopying newinfo.html external file to $TARGET"
	   		         scp $DOCROOT_HOME/newinfo_ext.html $USER@$TARGET:$DOCROOT_HOME/newinfo.html
	   		    fi
	   		    (( count = count + 1))
			  done
	    else
	      print "No instances to move IFrame file to"
		 fi
	 else
	    print "Nothing to move for $ENV"
    fi
}

############################################################################
# Movedrp
############################################################################

#Movedrp() {
#  if [[ "$ENV" == "prod" ]]; then
#      print "\nNow updating the DR instance."
#      TARGET="mxdrap1.dfw.is.keysight.com"
#	   print "\nCopying static file to $TARGET"
#	   scp $WAR_HOME/3dspace_static.zip $USER@$TARGET:$DOCROOT_HOME
#		print "Now unziping static content on $TARGET"
#		ssh $TARGET -C "cd $DOCROOT_HOME; /opt/matrixone/$ENV/java/$JDK_VER/bin/jar -xvf 3dspace_static.zip"
#
#		print "\nCopying war file to $TARGET"
#	  	scp $WAR_HOME/3dspace.war $USER@$TARGET:$WAR_HOME
#
#	  	print "\nNow updating the External DR instances."
#      TARGET="mxpedr2.dfw.dmz.keysight.com"
#      print "\nCopying static file to $TARGET"
#	   scp $WAR_HOME/external/3dspace_static.zip $USER@$TARGET:$DOCROOT_HOME
#		print "Now unziping static content on $TARGET"
#		ssh $TARGET -C "cd $DOCROOT_HOME; /opt/matrixone/$ENV/java/$JDK_VER/bin/jar -xvf 3dspace_static.zip"
#
#      TARGET="mxpedr2.dfw.is.keysight.com"
#      print "\nCopying war file to $TARGET"
#	  	scp $WAR_HOME/external/3dspace.war $USER@$TARGET:$WAR_HOME
#  fi
#}

############################################################################
# main
############################################################################
# lets do some tests
if (($# < 2)); then
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

# now for the action
case $CMD in
  moveall)   		Movewar
  						#Movestatic
  						#Movedrp
                  ;;
  movewar)			Movewar
  						;;
  moveonly)       START=FALSE
                  Movewar
  						#Movestatic
  						#Movedrp
                  ;;
  movestatic)     #Movestatic
  						;;
  moveiframe)     MoveIFrame
                  ;;
  #movedrp)        #Movedrp
                  #;;
  stopall)			Stopall
  						;;
  startall)			Startall
  						;;
  bounceall)		Stopall
  						Startall
  						;;
  *)              print "\nError: Unrecognized command: $CMD"
                  Usage
                  exit
                   ;;
esac

print "\nFINISHED!"
return 0
