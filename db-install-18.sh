#https://docs.oracle.com/en/database/oracle/oracle-database/18/shard/sharding-deployment.html#GUID-96ABB404-844C-457E-9C10-2D5C352D3928
#https://docs.oracle.com/en/database/oracle/oracle-database/12.2/gsmug/gdsctl-reference.html#GUID-8C21C4B2-0270-4CED-8C7D-5E3574457324

serverFQDN=`hostname -f`
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_db_$start.log
echo "start " `date +%m-%d-%Y-%H-%M-%S` > $logfile


##### ora18.env sharddirector
export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
##export ORACLE_SID=shardcat
export DATA_DIR=/u01/app/oracle/oradata18
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib






## install oracle 18 software
rm -rf $ORACLE_HOME $DATA_DIR ${ORACLE_BASE}/fast_recovery_area
mkdir -p $ORACLE_HOME
mkdir -p $DATA_DIR
mkdir -p ${ORACLE_BASE}/fast_recovery_area

cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_180000_db_home.zip

echo "install DB software in silent more"
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

echo "delete previous db if exists"
dbca -silent -deleteDatabase -sourceDB shardcat -sysDBAUserName sys -sysDBAPassword SysPassword1
lsnrctl stop
mv $ORACLE_HOME/network/admin/linstener.ora /home/oracle/scripts/listener.ora-original
mv $ORACLE_HOME/networdk/admin/tnsnames.ora /home/oracle/scripts/tnsnames.ora-ORIGINAL

#netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp
#lsnrctl status
#lsnrctl start

echo "install shard database"
sudo mv /etc/oratab /etc/oratab-ORGINAL
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
	 -initParams db_recovery_file_dest=$ORACLE_BASE/fast_recovery_area/$server  \
	 db_recovery_file_dest_size=20G  db_create_file_dest=$DATA_DIR STREAMS_POOL_SIZE=1200M \
     -totalMemory 5000                                                         \
     -storageType FS                                                           \
     -datafileDestination "${DATA_DIR}"                                        \
     -redoLogFileSize 50                                                       \
     -emConfiguration NONE                                                   \
	 -createListener LISTENER:1521  \
	 -customScripts /home/oracle/scripts/init.sql \
     -ignorePreReqs

### install the catalog database
echo "install catalog database"
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
     -customScripts /home/oracle/scripts/initshardcat.sql  \
     -ignorePreReqs


### configuration of the catalog
## this is done with initshardcat.sql
#install the gds services


env |grep ORA

#### gds18.env
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/18.0.0/gsmhome_1
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

end=`date +%s`
echo Execution time was `expr $end - $start` seconds. >> $logfile
total_time=`expr $end - $start`
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script completed in $minutes minutes and $seconds seconds" >> $logfile
