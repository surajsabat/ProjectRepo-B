======================================
Steps to Load Generic Users in 3DSpace
======================================
1. Copy LoadTestUsersInSpace.txt to a directory (e.g. TEMP_DIR) in mxdap3.cos.is.keysight.com server. 
2. Switch to instance owner (mxbst).
3. Change the current working direcrtory to /opt/matrixone/3dbst/r2017x/3dspace/server/scripts.
4. Execute below command to load the generic users in 3DSpace.
VPLMPosImport.sh -user admin_platform -password Horsetooth17 -context "VPLMAdmin.Keysight Technologies.Default" -server "http://mxdap3.cos.is.keysight.com:8520/internal" -file /TEMP_DIR/LoadTestUsersInSpace.txt
5. Copy AssignGroupAndSite.mql and AssignNationality.mql to mxdap3.cos.is.keysight.com server. 
6. Login to mql.
7. Run AssignDepartmentToTestUsers.mql, AssignGroupAndSite.mql and AssignNationality.mql.


===========================================================
Steps to Load non Ldap users in Internal Passport (NOT REQUIRED - Because BST passport DB schema is exported and imported)
===========================================================
1. Copy LoadTestUserInPassport.txt to a directory (e.g. TEMP_DIR) in mxdpass5.cos.is.keysight.com server.
2. Switch to instance owner (mxbst).
3. Change the current working direcrtory to /opt/matrixone/3dbst/r2017x/3dpassport/linux_a64/code/command.
4. Execute below command to load the Suppliers in Passport.
PassportUserImport.sh -file /TEMP_DIR/LoadTestUserInPassport.txt -url https://3dpassport17xbst.cos.is.keysight.com/3dpassport -default_country USA -default_password Firedam123

===========================================================
Steps to Load Suppliers in External Passport (NOT REQUIRED - Because BST passport DB schema is exported and imported after refresh)
===========================================================
1. Copy LoadSETestUserInDMZPassport.txt to a directory (e.g. TEMP_DIR) in mxdecos4.cos.dmz.keysight.com server.
2. Switch to instance owner (mxbst).
3. Change the current working direcrtory to /opt/matrixone/3dbst/r2017x/3dpassport/linux_a64/code/command.
4. Execute below command to load the Suppliers in External Passport.
PassportUserImport.sh -file /TEMP_DIR/LoadSETestUserInDMZPassport.txt -url https://globalpassportbst.supplychain.keysight.com/3dpassport -default_country USA -default_password Firedam123