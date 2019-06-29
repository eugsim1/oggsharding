ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE FORCE LOGGING;
alter database archivelog;
alter user gsmuser account unlock identified by Welcome1;
grant sysdg,sysbackup to gsmuser;
grant read,write on directory DATA_PUMP_DIR to GSMADMIN_INTERNAL;
