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
export DATA_DIR=/u01/app/oracle/oradata
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

sed '/OraDB19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
cat /u01/app/oraInventory/ContentsXML/inventory.xml


sed '/OraGSM19Home1/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
cat /u01/app/oraInventory/ContentsXML/inventory.xml


## install oracle software
mkdir -p $ORACLE_HOME
cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_193000_db_home.zip



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


sudo touch /etc/oratab
sudo chmod ugo+rw /etc/oratab
sudo chown oracle:oinstall /etc/oratab
dbca -silent -createDatabase                                                   \
     -templateName General_Purpose.dbc                                         \
     -gdbname $server -sid  $server -responseFile NO_VALUE         \
     -characterSet AL32UTF8                  lab                                  \
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
	 -createListener LISTENER:1521  \
	 -customScripts init.sql \
     -ignorePreReqs
	 
