#!/bin/ksh
# mms.sh
# RAS
# runs the MatrixOne Management System Controller
# 03/04/2019 Vijay Noble - Keysight-ERI- Modified the Java home path to use 1.8
###################################################################
# Environment declarations
###################################################################
JAVA_HOME=/opt/matrixone/tools/java/jdk1.8.0_181
DIR=/opt/matrixone/tools/mms

############################################################################
# main
############################################################################

# need 1.6
$JAVA_HOME/bin/java -jar $DIR/mms.jar
ERR=$?

if [[ $ERR -ne 0 ]] ; then
  print ""
  print "    Error: $ERR"
  return $ERR
fi

return $ERR
