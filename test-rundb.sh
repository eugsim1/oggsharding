
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

lsnrctl status

cat /etc/oratab

ps -eaf | grep pmon 
