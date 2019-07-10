#### install gds services
#### gds19.env
serverFQDN=`hostname -f`
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_gds.log
echo "start " `date +%m-%d-%Y-%H-%M-%S` > $logfile

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/gsmhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export PATH=$ORACLE_HOME/bin:$PATH
export ORA_INVENTORY=/u01/app/oraInventory

if [[ $server == "sharddirector" ]]
then

echo "install gds on server $server" >> $logfile

sed '/gsmhome/d' /u01/app/oraInventory/ContentsXML/inventory.xml | sed '/OUIPlaceHolderDummyHome/d' > /tmp/loc.xml
mv /tmp/loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
cat /u01/app/oraInventory/ContentsXML/inventory.xml >> $logfile
echo "                   " >> $logfile
echo "gds pre install" >> $logfile
cat /u01/app/oraInventory/ContentsXML/inventory.xml   >> $logfile
echo "          " >> $logfile

rm -rf $ORACLE_HOME
mkdir -p $ORACLE_HOME

cd /tmp
unzip -oq /u01/stage/LINUX.X64_180000_gsm.zip


echo "begin gds installer `date` ">> $logfile
/tmp/gms/runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /tmp/gsm/response/gsm_install.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
    SELECTED_LANGUAGES=en,en_GB                                                \
    ORACLE_HOME=${ORACLE_HOME}                                                 \
    ORACLE_BASE=${ORACLE_BASE}                                                 \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                                 \
    DECLINE_SECURITY_UPDATES=true >2&>1 >> $logfile

echo "end gds installer `date`">> $logfile
sudo  $ORACLE_HOME/root.sh

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/gsmhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export PATH=$ORACLE_HOME/bin:$PATH
export ORA_INVENTORY=/u01/app/oraInventory

echo "change settings for gds configuration" >> $logfile
env | grep ORA >> $logfile
env | grep PATH >> $logfile

echo "           ">> $logfile
echo "begin gdsctl commands" >> $logfile


gdsctl delete catalog  -force >> $logfile
gdsctl create shardcatalog -database sharddirector:1521/shardcat -user mysdbadmin/Welcome1 -sdb cust_sdb -region region1, region2 -agent_port 7777 -agent_password Welcome1 -sharding system -force >> $logfile
gdsctl add gsm -gsm sharddirector1  -pwd Welcome1 -listener 1522 -catalog sharddirector:1521:shardcat -region region1 -trace_level 16 >> $logfile
gdsctl start gsm -gsm sharddirector1 >> $logfile
gdsctl add credential -credential mycredential -osaccount oracle -ospassword Toula1412# >> $logfile

echo "end gdsctl command" >> $logfile

fi

end=`date +%s`
echo Execution time was `expr $end - $start` seconds. >> $logfile
total_time=`expr $end - $start`
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script completed in $minutes minutes and $seconds seconds" >> $logfile
