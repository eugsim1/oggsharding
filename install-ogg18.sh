##ogg18.env
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/dbhome_1
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH

export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export  OGG_BIN=/u01/app/ogg/oggbin
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$PATH
export JAVA_HOME=/u01/app/ogg/oggma/jdk
OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

### install ogg ma core software
rm -rf $OGG_BASE
mkdir -p $OGG_BASE
mkdir -p $OGG_BIN
export OGG_HOME=/u01/app/ogg
echo $OGG_HOME
cd $OGG_BIN
unzip -oq /u01/stage/V980003-01.zip
cd fbo_ggs_Linux_x64_services_shiphome/Disk1

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /u01/app/ogg/oggbin/fbo_ggs_Linux_x64_services_shiphome/Disk1/response/oggcore.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
	INSTALL_OPTION=ORA18c   SOFTWARE_LOCATION=${OGG_BASE}/oggma
