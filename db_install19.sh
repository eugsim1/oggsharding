###source ~/scripts/oggsharding/ora19.env
##### ora19.env sharddirector
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_$start.log
echo "start " $start > $logfile


export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=$server
export DATA_DIR=/u01/app/oracle/oradata19
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export TNS_ADMIN=$ORACLE_HOME/network/admin

### kill all previous ogg sessions on this server
env | grep ORA >> $logfile
env | grep TNS >> $logfile

### create a new oggma deployement from scratch
for pid in $(ps -ef | grep "oggma" | awk '{print $2}'); do kill -9 $pid; done

## kill all db sessions on this server
for pid in $(ps -ef | grep "pmon" | awk '{print $2}'); do kill -9 $pid; done


## kill all db sessions on this server
for pid in $(ps -ef | grep "lsnr" | awk '{print $2}'); do kill -9 $pid; done

sed '/OraDB19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml

## remove previous entries from inventory clean install
sed '/OraGSM19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml | sed '/OUIPlaceHolderDummyHome/d' > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml



cat /u01/app/oraInventory/ContentsXML/inventory.xml >> $logfile

cd $ORACLE_BASE
rm -rf *
rm -rf $DATA_DIR
rm -rf $ORACLE_HOME
rm -rf ../ogg ..//ogg19
## install oracle software
mkdir -p $DATA_DIR
mkdir -p $ORACLE_HOME

echo "start unzip V982063-01.zip" `date +%s` >> $logfile

cd $ORACLE_HOME
unzip -oq /u01/stage/V982063-01.zip

echo "end unzip V982063-01.zip" `date +%s` >> $logfile
echo " ********************************"   >> $logfile
echo " start install db software"          >> $logfile

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
    DECLINE_SECURITY_UPDATES=true 2&>1 >> $logfile
    
sudo   /u01/app/oraInventory/orainstRoot.sh
sudo  /u01/app/oracle/product/19.0.0/dbhome_1/root.sh
	
	
### install ogg ma software
### oraenv for ora 19 version
export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
export JAVA_HOME=$OGG_HOME/jdk
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$PATH

OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

### kill all previous ogg sessions on this server
env | grep ORA >> $logfile
env | grep TNS >> $logfile
### create a new oggma deployement from scratch
for pid in $(ps -ef | grep "oggma" | awk '{print $2}');  do kill -9 $pid; done

# remove previous entries from the inventory file

sed '/oggma/d' /u01/app/oraInventory/ContentsXML/inventory.xml | sed '/OUIPlaceHolderDummyHome/d' > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
echo "oggma pre install" >> /home/oracle/ansible.log
cat /u01/app/oraInventory/ContentsXML/inventory.xml  >> $logfile

### install ogg ma core software
rm -rf $OGG_BASE
mkdir -p $OGG_BASE
mkdir -p $OGG_BIN
export OGG_HOME=/u01/app/ogg
echo $OGG_HOME >> $logfile
cd $OGG_BIN
unzip -oq /u01/stage/191001_fbo_ggs_Linux_x64_services_shiphome.zip
cd fbo_ggs_Linux_x64_services_shiphome/Disk1

echo "begin install oggma software " >> $logfile

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /u01/app/ogg/oggbin/fbo_ggs_Linux_x64_services_shiphome/Disk1/response/oggcore.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
	INSTALL_OPTION=ORA19c   SOFTWARE_LOCATION=${OGG_BASE}/oggma 2&>1 >> $logfile
	
which java  >> $logfile
which orapki >> $logfile

	
#### configure databases
echo "netca config" >> $logfile
netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp 2&>1 >> $logfile

sudo rm -rf /etc/oratab
sudo touch /etc/oratab
sudo chmod ugo+rw /etc/oratab
sudo chown oracle:oinstall /etc/oratab
 serverDB=`echo $server | cut -c 1-12`
if [[ $server != "sharddirector" ]]
then 
dbca -silent -createDatabase                                                   \
     -templateName General_Purpose.dbc                                         \
     -gdbname $serverDB -sid  $serverDB -responseFile NO_VALUE         \
     -characterSet AL32UTF8                                                    \
     -sysPassword SysPassword1                                                 \
     -systemPassword SysPassword1                                              \
     -createAsContainerDatabase false                                           \
     -databaseType MULTIPURPOSE                                                \
     -automaticMemoryManagement false                                          \
	 -enableArchive true   \
	 -initParams db_recovery_file_dest=${ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME}  \
	 db_recovery_file_dest_size=20G  STREAMS_POOL_SIZE=1200M \
     -totalMemory 5000                                                         \
     -storageType FS                                                           \
     -datafileDestination "${DATA_DIR}"                                        \
     -redoLogFileSize 50                                                       \
     -emConfiguration NONE                                                   \
     -ignorePreReqs 2&>1 >> $logfile
     
 ###    	 -customScripts init.sql \
 
export ORACLE_SID=$serverDB	 
sqlplus / as sysdba<<EOF
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE FORCE LOGGING;
shutdown immediate;
startup mount;
alter database open;
alter database archivelog;
alter user gsmuser account unlock identified by Welcome1;
grant sysdg,sysbackup to gsmuser;
grant read,write on directory DATA_PUMP_DIR to GSMADMIN_INTERNAL;
SELECT SUPPLEMENTAL_LOG_DATA_MIN, FORCE_LOGGING FROM V\$DATABASE;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SWITCH LOGFILE;
select * from v\$sgainfo;
alter system set streams_pool_size = '1200M' scope = both;
select current_size from v\$sga_dynamic_components where component = 'streams pool';
EOF


fi


#### install shardcate database
	
### install the catalog database

if [[ $server == "sharddirector" ]]
then
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
     -ignorePreReqs 2&>1 >> $logfile	

export ORACLE_SID=shardcat
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
@/u01/app/ogg/oggma/lib/sql/sharding/ggsys_setup.sql
EOF


#### install gds services
#### gds19.env
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/gsmhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export PATH=$ORACLE_HOME/bin:$PATH
export ORA_INVENTORY=/u01/app/oraInventory

rm -rf $ORACLE_HOME
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/V982067-01.zip

"echo install gds " >> $logfile


#unzip -oq /u01/stage/linuxx64_12201_gsm.zip
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
    DECLINE_SECURITY_UPDATES=true 2&>1 >> $logfile
    
sudo  $ORACLE_HOME/root.sh

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/gsmhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export PATH=$ORACLE_HOME/bin:$PATH
export ORA_INVENTORY=/u01/app/oraInventory


gdsctl delete catalog  -force
gdsctl create shardcatalog -database sharddirector:1521/shardcat -user mysdbadmin/Welcome1 -sdb cust_sdb -region region1, region2 -agent_port 7777 -agent_password Welcome1 -sharding system -force
gdsctl add gsm -gsm sharddirector1  -pwd Welcome1 -listener 1522 -catalog sharddirector:1521:shardcat -region region1 -trace_level 16
gdsctl start gsm -gsm sharddirector1
gdsctl add credential -credential mycredential -osaccount oracle -ospassword Toula1412#

fi

