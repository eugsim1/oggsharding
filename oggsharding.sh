serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server
sqlplus / as sysdba <<EOF
@$OGG_HOME/lib/sql/sharding/orashard_setup.sql A $server:9001/oggma_fisrt Welcome1 $server:1521/$server;
EOF
