###source ~/scripts/oggsharding/ora19.env
##### ora19.env sharddirector
serverFQDN=`hostname -f`
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_db.log
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

### kill all previous ogg sessions on this server
env | grep ORA >> $logfile
env | grep TNS >> $logfile
env | grep PATH >> $logfile
echo "         ">> $logfile

### create a new oggma deployement from scratch
#for pid in $(ps -ef | grep "oggma" | awk '{print $2}'); do kill -9 $pid; done

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

cd $ORACLE_BASE #/u01/app/oracle
rm -rf *
# rm -rf $DATA_DIR #/u01/app/oracle/oradata19
# rm -rf $ORACLE_HOME
# rm -rf ../ogg ..//ogg19
## install oracle software
mkdir -p $DATA_DIR
mkdir -p $ORACLE_HOME
mkdir -p /u01/app/oracle/admin/$server/adump

echo "start unzip LINUX.X64_193000_db_home.zip" `date +%s` >> $logfile

cd $ORACLE_HOME
unzip -oq /u01/stage/LINUX.X64_193000_db_home.zip

echo "end unzip LINUX.X64_193000_db_home.zip" `date +%s` >> $logfile
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
    DECLINE_SECURITY_UPDATES=true > 2&>1 >> $logfile

sudo   /u01/app/oraInventory/orainstRoot.sh
sudo  /u01/app/oracle/product/19.0.0/dbhome_1/root.sh


end=`date +%s`
echo Execution time was `expr $end - $start` seconds. >> $logfile
total_time=`expr $end - $start`
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script completed in $minutes minutes and $seconds seconds" >> $logfile
