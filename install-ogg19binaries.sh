### install ogg ma software
### oraenv for ora 19 version

serverFQDN=`hostname -f`
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

start=`date +%s`
logfile=/tmp/debug_log_ogg.log
echo "start " `date +%m-%d-%Y-%H-%M-%S` > $logfile

export logfile
export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
export JAVA_HOME=$OGG_HOME/jdk
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$ORACLE_HOME/bin:$PATH

OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

### kill all previous ogg sessions on this server
echo "before oggma install " >> $logfile
echo "                     " >> $logfile
env | grep ORA >> $logfile
env | grep TNS >> $logfile
env | grep PATH >> $logfile
echo "                     " >>$logfile
### create a new oggma deployement from scratch
for pid in $(ps -ef | grep "oggma" | awk '{print $2}');  do kill -9 $pid; done

# remove previous entries from the inventory file

sed '/oggma/d' /u01/app/oraInventory/ContentsXML/inventory.xml | sed '/OUIPlaceHolderDummyHome/d' > /tmp/loc.xml
mv /tmp/loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
echo "oggma pre install" >> $logfile
cat /u01/app/oraInventory/ContentsXML/inventory.xml   >> $logfile
echo "          " >> $logfile

### install ogg ma core software
rm -rf $OGG_BASE # /u01/app/ogg
mkdir -p $OGG_BASE
mkdir -p $OGG_BIN # /u01/app/ogg/oggbin
export OGG_HOME=/u01/app/ogg
echo "$OGG_HOME" $OGG_HOME >> $logfile
cd $OGG_BIN
unzip -oq /u01/stage/191001_fbo_ggs_Linux_x64_services_shiphome.zip
cd fbo_ggs_Linux_x64_services_shiphome/Disk1

echo "begin install oggma software=> `date`" >> $logfile

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /u01/app/ogg/oggbin/fbo_ggs_Linux_x64_services_shiphome/Disk1/response/oggcore.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
	INSTALL_OPTION=ORA19c   SOFTWARE_LOCATION=${OGG_BASE}/oggma > 2&>1 >> $logfile

echo "end install oggma=> `date`" >> $logfile

which java  >> $logfile
which orapki >> $logfile


end=`date +%s`
echo Execution time was `expr $end - $start` seconds. >> $logfile
total_time=`expr $end - $start`
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo "Script completed in $minutes minutes and $seconds seconds" >> $logfile
