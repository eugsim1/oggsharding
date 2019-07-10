serverFQDN=`hostname -f`
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_inst_$start.log
echo "start " `date +%m-%d-%Y-%H-%M-%S` > $logfile


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

env | grep ORA >> $logfile
env | grep PATH >> $logfile


#### configure databases
echo "netca config" >> $logfile
netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp > 2&>1 >> $logfile

echo "listener content" >> $logfile
cat $TNS_ADMIN/listener.ora >> $logfile
echo `lsnrctl status` >> $logfile
echo "               ">> $logfile
sudo rm -rf /etc/oratab
sudo touch /etc/oratab
sudo chmod ugo+rw /etc/oratab
sudo chown oracle:oinstall /etc/oratab
serverDB=`echo $server | cut -c 1-12`

echo "before db server creation $serverDB `date`" >> $logfile

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
   -ignorePreReqs  > 2&>1 >> $logfile

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
mkdir -p  /u01/app/oracle/admin/shardcat/adump
echo "shardirector create shardcat database" >> $logfile
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
   -ignorePreReqs >2&>1 >> $logfile

export ORACLE_SID=shardcat
sqlplus / as sysdba<<EOF > 2&1>> $logfile
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
fi


end=`date +%s`
echo Execution time was `expr $end - $start` seconds. >> $logfile
total_time=`expr $end - $start`
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script completed in $minutes minutes and $seconds seconds" >> $logfile
