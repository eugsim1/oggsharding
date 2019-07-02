###source ~/scripts/oggsharding/ora19.env
##### ora19.env sharddirector
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

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
env | grep ORA
env | grep TNS
### create a new oggma deployement from scratch
for pid in $(ps -ef | grep "oggma" | awk '{print $2}'); do kill -9 $pid; done

## kill all db sessions on this server
for pid in $(ps -ef | grep "pmon" | awk '{print $2}'); do kill -9 $pid; done


## kill all db sessions on this server
for pid in $(ps -ef | grep "lsnr" | awk '{print $2}'); do kill -9 $pid; done

sed '/OraDB19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
cat /u01/app/oraInventory/ContentsXML/inventory.xml

## remove previous entries from inventory clean install
sed '/OraGSM19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
cat /u01/app/oraInventory/ContentsXML/inventory.xml

rm -rf $DATA_DIR
rm -rf $ORACLE_HOME
## install oracle software
mkdir -p $DATA_DIR
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/V982063-01.zip



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
sudo  /u01/app/oracle/product/19.0.0/dbhome_1/root.sh

netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp

sudo rm -rf /etc/oratab
sudo touch /etc/oratab
sudo chmod ugo+rw /etc/oratab
sudo chown oracle:oinstall /etc/oratab
dbca -silent -createDatabase                                                   \
     -templateName General_Purpose.dbc                                         \
     -gdbname $server -sid  $server -responseFile NO_VALUE         \
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
     -ignorePreReqs
     
 ###    	 -customScripts init.sql \
 
 export ORACLE_SID=$server	 
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


#### install shardcate database
	
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
    DECLINE_SECURITY_UPDATES=true

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

