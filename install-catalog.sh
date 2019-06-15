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

