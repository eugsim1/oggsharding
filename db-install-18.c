https://docs.oracle.com/en/database/oracle/oracle-database/18/shard/sharding-deployment.html#GUID-96ABB404-844C-457E-9C10-2D5C352D3928
https://docs.oracle.com/en/database/oracle/oracle-database/12.2/gsmug/gdsctl-reference.html#GUID-8C21C4B2-0270-4CED-8C7D-5E3574457324


##### ora19.env sharddirector
export ORACLE_HOSTNAME=sharddirector
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=shardcat
export DATA_DIR=/u01/app/oracle/oradata
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

##### ora18.env sharddirector
export ORACLE_HOSTNAME=sharddirector
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=shardcat
export DATA_DIR=/u01/app/oracle/oradata
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

##### ora12.env sharddirector
export ORACLE_HOSTNAME=sharddirector
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=shardcat
export DATA_DIR=/u01/app/oracle/oradata
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib




## install oracle 18 software
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_180000_db_home.zip

# Install DB software Silent mode.
./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile ${ORACLE_HOME}/install/response/db_install.rsp               \
    oracle.install.option=INSTALL_DB_SWONLY                                    \
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                                         \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
    SELECTED_LANGUAGES=en,en_GB                                                \
    ORACLE_HOME=${ORACLE_HOME}                                                 \
    ORACLE_BASE=${ORACLE_BASE}                                                 \
    oracle.install.db.InstallEdition=EE                                        \
    oracle.install.db.OSDBA_GROUP=dba                                          \
    oracle.install.db.OSBACKUPDBA_GROUP=dba                                    \
    oracle.install.db.OSDGDBA_GROUP=dba                                        \
    oracle.install.db.OSKMDBA_GROUP=dba                                        \
    oracle.install.db.OSRACDBA_GROUP=dba                                       \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                                 \
    DECLINE_SECURITY_UPDATES=true
	
## install oracle 12 software
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_120000_db_home.zip

# Install DB software Silent mode.
./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile ${ORACLE_HOME}/install/response/db_install.rsp               \
    oracle.install.option=INSTALL_DB_SWONLY                                    \
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                                         \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
    SELECTED_LANGUAGES=en,en_GB                                                \
    ORACLE_HOME=${ORACLE_HOME}                                                 \
    ORACLE_BASE=${ORACLE_BASE}                                                 \
    oracle.install.db.InstallEdition=EE                                        \
    oracle.install.db.OSDBA_GROUP=dba                                          \
    oracle.install.db.OSBACKUPDBA_GROUP=dba                                    \
    oracle.install.db.OSDGDBA_GROUP=dba                                        \
    oracle.install.db.OSKMDBA_GROUP=dba                                        \
    oracle.install.db.OSRACDBA_GROUP=dba                                       \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                                 \
    DECLINE_SECURITY_UPDATES=true	

		
sudo   /u01/app/oraInventory/orainstRoot.sh
sudo  /u01/app/oracle/product/18.0.0/dbhome_1/root.sh	

	
### clean previous database installations
source /home/oracle/scripts/ora12.env
source /home/oracle/scripts/ora18.env
source /home/oracle/scripts/ora19.env
dbca -silent -deleteDatabase -sourceDB shardcat -sysDBAUserName sys -sysDBAPassword SysPassword1
lsnrctl stop
mv $ORACLE_HOME/network/admin/linstener.ora /home/oracle/scripts/listener.ora-original
mv $ORACLE_HOME/networdk/admin/tnsnames.ora /home/oracle/scripts/tnsnames.ora-ORIGINAL

netca/netcaa -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp
lsnrctl status
lsnrctl start


	
### install the catalog database
dbca -silent -createDatabase                                                   \
     -templateName General_Purpose.dbc                                         \
     -gdbname shardcat -sid  shardcat -responseFile NO_VALUE         \
     -characterSet AL32UTF8                                                    \
     -sysPassword SysPassword1                                                 \
     -systemPassword SysPassword1                                              \
     -createAsContainerDatabase false                                           \
     -databaseType MULTIPURPOSE                                                \
     -automaticMemoryManagement false                                          \
     -totalMemory 2000                                                         \
     -storageType FS                                                           \
     -datafileDestination "${DATA_DIR}"                                        \
     -redoLogFileSize 50                                                       \
     -emConfiguration NONE                                                     \
     -ignorePreReqs	
	
	
### configuration of the catalog

source /home/oracle/scripts/ora12.env
source /home/oracle/scripts/ora18.env
source /home/oracle/scripts/ora19.env
sqlplus / as sysdba<<EOF
alter system set db_create_file_dest='/u01/app/oracle/oradata' scope=both;
alter system set open_links=16 scope=spfile;
alter system set open_links_per_instance=16 scope=spfile;
shutdown immediate;
startup;
set echo on;
set termout on;
spool setup_grants_privs.lst;
alter user gsmcatuser account unlock;
alter user gsmcatuser identified by Welcome1;
create user mysdbadmin identified by Welcome1;
grant connect, create session, gsmadmin_role to mysdbadmin;
grant inherit privileges on user SYS to GSMADMIN_INTERNAL;
spool off;
EOF




	
	
#install the gds services 	


env |grep ORA
#### gds12.env
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/12.0.0/gsmhome_1
#export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH

#### gds18.env
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/18.0.0/gsmhome_1
#export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH

#### gds19.env
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/gsmhome_1
#export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH

rm -rf $ORACLE_HOME
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_180000_gsm.zip

mkdir -p $ORACLE_HOME/gsm
cd $ORACLE_HOME/gsm

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile ${ORACLE_HOME}/gsm/response/gsm_install.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
    SELECTED_LANGUAGES=en,en_GB                                                \
    ORACLE_HOME=${ORACLE_HOME}                                                 \
    ORACLE_BASE=${ORACLE_BASE}                                                 \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                                 \
    DECLINE_SECURITY_UPDATES=true
##
# /u01/app/oracle/product/19.0.0/gsmhome_1/install/response/gsm_2019-06-03_05-51-33AM.rsp
#	


sudo  $ORACLE_HOME/root.sh

### install oggma

ora.evn

#export ORACLE_HOSTNAME=sharddirector


ogg18.env
export ORACLE_SID=shardcat
TNS_ADMIN=${ORACLE_HOME}/network/admin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export  OGG_HOME=/u01/app/ogg/oggma
export  OGG_BIN=/u01/app/ogg/oggbin
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$PATH
export JAVA_HOME=/u01/app/ogg/oggma/jdk
OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

rm -rf /u01/app/ogg
mkdir -p $OGG_HOME
mkdir -p  $OGG_BIN
export OGG_HOME=/u01/app/ogg
echo $OGG_HOME
cd $OGG_BIN
unzip -oq /u01/stage/181000_fbo_ggs_Linux_x64_services_shiphome.zip
cd fbo_ggs_Linux_x64_services_shiphome/Disk1

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /u01/app/ogg/oggbin/fbo_ggs_Linux_x64_services_shiphome/Disk1/response/oggcore.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
	INSTALL_OPTION=ORA18c   SOFTWARE_LOCATION=${OGG_HOME}/oggma
	

	
rm -rf 	$ORACLE_BASE/admin/ggshd_wallet
mkdir -p $ORACLE_BASE/admin/ggshd_wallet


export 	OGG_HOME=/u01/app/ogg/oggma
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$PATH
export JAVA_HOME=/u01/app/ogg/oggma/jdk
OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

orapki wallet create -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -pwd Welcome1  -auto_login
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -dn "CN=RootCA" -keysize 2048 -self_signed -validity 7300 -pwd Welcome1
orapki wallet export -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca  -dn "CN=RootCA" -cert $ORACLE_BASE/admin/ggshd_wallet/rootCA_Cert.pem -pwd Welcome1


orapki wallet create -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -auto_login -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -dn "CN=sharddirector" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -dn "CN=sharddirector" -request $ORACLE_BASE/admin/ggshd_wallet/sharddirector_req.pem -pwd Welcome1

orapki cert create -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -request $ORACLE_BASE/admin/ggshd_wallet/sharddirector_req.pem -cert $ORACLE_BASE/admin/ggshd_wallet/sharddirector_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -trusted_cert -cert $ORACLE_BASE/admin/ggshd_wallet/rootCA_Cert.pem -pwd Welcome1 
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -user_cert -cert $ORACLE_BASE/admin/ggshd_wallet/sharddirector_Cert.pem -pwd Welcome1

orapki wallet create -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -auto_login -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -dn "CN=sharddirector" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -dn "CN=sharddirector" -request $ORACLE_BASE/admin/ggshd_wallet/dist_client_req.pem -pwd Welcome1
orapki cert create -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -request $ORACLE_BASE/admin/ggshd_wallet/dist_client_req.pem -cert $ORACLE_BASE/admin/ggshd_wallet/dist_client_Cert.pem -serial_num 30 -validity 365 -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -trusted_cert -cert $ORACLE_BASE/admin/ggshd_wallet/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -user_cert -cert $ORACLE_BASE/admin/ggshd_wallet/dist_client_Cert.pem -pwd Welcome1



orapki wallet create -wallet $ORACLE_BASE/admin/ggshd_wallet/shard1 -auto_login -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/shard1 -dn "CN=shard1" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $ORACLE_BASE/admin/ggshd_wallet/shard1 -dn "CN=shard1" -request $ORACLE_BASE/admin/ggshd_wallet/shard1_req.pem -pwd Welcome1
orapki cert create -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -request $ORACLE_BASE/admin/ggshd_wallet/shard1_req.pem -cert $ORACLE_BASE/admin/ggshd_wallet/shard1_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/shard1 -trusted_cert -cert $ORACLE_BASE/admin/ggshd_wallet/rootCA_Cert.pem -pwd Welcome1 
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/shard1 -user_cert -cert $ORACLE_BASE/admin/ggshd_wallet/shard1_Cert.pem -pwd Welcome1

orapki wallet create -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -auto_login -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -dn "CN=shard1" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -dn "CN=shard1" -request $ORACLE_BASE/admin/ggshd_wallet/dist_client_req.pem -pwd Welcome1
orapki cert create -wallet $ORACLE_BASE/admin/ggshd_wallet/root_ca -request $ORACLE_BASE/admin/ggshd_wallet/dist_client_req.pem -cert $ORACLE_BASE/admin/ggshd_wallet/dist_client_Cert.pem -serial_num 30 -validity 365 -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -trusted_cert -cert $ORACLE_BASE/admin/ggshd_wallet/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -user_cert -cert $ORACLE_BASE/admin/ggshd_wallet/dist_client_Cert.pem -pwd Welcome1

orapki wallet display -wallet $ORACLE_BASE/admin/ggshd_wallet/dist_client -pwd Welcome1
orapki wallet display -wallet $ORACLE_BASE/admin/ggshd_wallet/sharddirector -pwd Welcome1

### configure oggma
./${OGG_HOME}/oggma/oggca.sh -silent -responseFile /home/oracle/scripts/oggca.rsp


## configure gsm catalog services	

source /home/oracle/scripts/gsm18.env

#gdsctl delete catalog  -force
gdsctl create shardcatalog -database sharddirector:1521/shardcat -user mysdbadmin/Welcome1 -sdb cust_sdb -region region1, region2 -agent_port 7777 -agent_password Welcome1 -sharding system -force
gdsctl add gsm -gsm sharddirector1  -pwd Welcome1 -listener 1522 -catalog sharddirector:1521:shardcat -region region1 -trace_level 16
gdsctl start gsm -gsm sharddirector1
gdsctl add credential -credential mycredential -osaccount oracle -ospassword Toula1412#




Specify the topology layout using the following commands.

    CREATE SHARDCATALOG
    ADD GSM
    START GSM
    ADD CREDENTIAL (if using CREATE SHARD)
    ADD SHARDGROUP
    ADD INVITEDNODE
    CREATE SHARD (or ADD SHARD) for each shard

Run DEPLOY and add the global service to access any shard in the sharded database.

    DEPLOY
    ADD SERVICE



#gdsctl delete catalog  -force
gdsctl status
gdsctl create shardcatalog -database sharddirector:1521/shardcat -user mysdbadmin/Welcome1 -repl OGG -repfactor 2 -sdb cust_sdb -region region1, region2 -agent_port 7777 -agent_password Welcome1 -force -sharding system -force
gdsctl add gsm -gsm sharddirector1  -pwd Welcome1 -catalog 127.0.0.1:1521:shardcat -listener  1522 -region region1
gdsctl start gsm -gsm sharddirector1
gdsctl add credential -credential mycredential -osaccount oracle -ospassword Toula1412#
gdsctl add shardgroup -shardgroup shardgroup1 -region region1 -repfactor 2
gdsctl add invitednode shard1
gdsctl create shard -shardgroup shardgroup1 -destination shard1  -credential mycredential  -gg_service shard1:9002/oggma_first  -gg_password Welcome1  -dbtemplatefile /u01/app/oracle/product/19.0.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc