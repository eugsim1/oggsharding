##ogg19.env
!#/bin/bash
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server


### oraenv for ora 19 version
export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH

:'
### oraenv for ora 18 version
export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/dbhome_1
'

export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
export JAVA_HOME=$OGG_HOME/jdk
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$PATH

OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

### kill all previous ogg sessions on this server
env | grep ORA
env | grep TNS
### create a new oggma deployement from scratch
for pid in $(ps -ef | grep "oggma" | awk '{print $2}');  do kill -9 $pid; done


# remove previous entries from the inventory file
#sed '/oggma/d' /u01/app/oraInventory/ContentsXML/inventory.xml > loc.xml
#mv loc.xml /u01/app/oraInventory/ContentsXML/inventory.xml
#cat /u01/app/oraInventory/ContentsXML/inventory.xml

:'
### install ogg ma core software
rm -rf $OGG_BASE
mkdir -p $OGG_BASE
mkdir -p $OGG_BIN
export OGG_HOME=/u01/app/ogg
echo $OGG_HOME
cd $OGG_BIN
unzip -oq /u01/stage/191001_fbo_ggs_Linux_x64_services_shiphome.zip
cd fbo_ggs_Linux_x64_services_shiphome/Disk1

./runInstaller -ignorePrereq -waitforcompletion -silent                        \
    -responseFile /u01/app/ogg/oggbin/fbo_ggs_Linux_x64_services_shiphome/Disk1/response/oggcore.rsp               \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORA_INVENTORY}                                        \
	INSTALL_OPTION=ORA19c   SOFTWARE_LOCATION=${OGG_BASE}/oggma
	
which java
which orapki
'

## create certificates for the oma deployement

serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server


export WALLET_DIR=$ORACLE_BASE/admin/wallet_dir
export SHARDIND_WALLET_DIR=$ORACLE_BASE/admin/ggshd_wallet
cd $ORACLE_BASE/admin	
rm -rf 	$WALLET_DIR $SHARDIND_WALLET_DIR
mkdir -p $ORACLE_BASE/admin/ggshd_wallet
mkdir -p $ORACLE_BASE/admin/wallet_dir
cd $ORACLE_BASE/admin


if [[ $server == "sharddirector" ]]
 then 
  orapki wallet create -wallet  $WALLET_DIR/root_ca -pwd Welcome1  -auto_login
  orapki wallet add -wallet $WALLET_DIR/root_ca -dn "CN=RootCA" -keysize 2048 -self_signed -validity 7300 -pwd Welcome1 -sign_alg sha256
  orapki wallet export -wallet $WALLET_DIR/root_ca  -dn "CN=RootCA" -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
  tar -cvf wallet_dir.tar wallet_dir
  scp wallet_dir.tar shard1:/$ORACLE_BASE/admin/
  scp wallet_dir.tar shard2:/$ORACLE_BASE/admin/
  scp wallet_dir.tar shard3:/$ORACLE_BASE/admin/
 else
  cd $ORACLE_BASE/admin
  tar -xvf wallet_dir.tar
fi


## create server certificate for the host short name not FQDN
orapki wallet create -wallet $WALLET_DIR/$server -auto_login -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/$server -dn "CN=$server" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $WALLET_DIR/$server -pwd Welcome1  -dn "CN=$server"  -request $WALLET_DIR/${server}_req.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $WALLET_DIR/${server}_req.pem -cert $WALLET_DIR/${server}_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1  -sign_alg sha256
orapki wallet add -wallet $WALLET_DIR/$server -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/$server -user_cert  -cert $WALLET_DIR/${server}_Cert.pem -pwd Welcome1
### display wallet configuration
orapki wallet display -wallet $WALLET_DIR/$server -pwd Welcome1
### create a distribution server user certificate
orapki wallet create -wallet $WALLET_DIR/dist_client -auto_login -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -dn "CN=$server" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $WALLET_DIR/dist_client -pwd Welcome1  -dn "CN=$server"  -request $WALLET_DIR/dist_client_req.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $WALLET_DIR/dist_client_req.pem -cert $WALLET_DIR/dist_client_Cert.pem -serial_num 30 -validity 365 -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -user_cert  -cert $WALLET_DIR/dist_client_Cert.pem -pwd Welcome1
### display wallet configuration
orapki wallet display -wallet  $WALLET_DIR/dist_client -pwd Welcome1


## create wallets
export WALLET_DIR=$ORACLE_BASE/admin/wallet_dir
export SHARDIND_WALLET_DIR=$ORACLE_BASE/admin/ggshd_wallet
orapki wallet create -wallet $SHARDIND_WALLET_DIR -pwd Welcome1  -auto_login
orapki wallet add -wallet $SHARDIND_WALLET_DIR -dn "CN=dist_client" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $SHARDIND_WALLET_DIR -pwd Welcome1  -dn "CN=dist_client"  -request $SHARDIND_WALLET_DIR/dist_client.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $SHARDIND_WALLET_DIR/dist_client.pem -cert $SHARDIND_WALLET_DIR/dist_client_Cert.pem -serial_num 40 -validity 365 -pwd Welcome1
orapki wallet add -wallet $SHARDIND_WALLET_DIR -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $SHARDIND_WALLET_DIR -user_cert  -cert $SHARDIND_WALLET_DIR/dist_client_Cert.pem -pwd Welcome1
orapki wallet display -wallet $SHARDIND_WALLET_DIR


### deployement of the oggma 

export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server
for pid in $(ps -ef | grep "oggma" | awk '{print $2}');  do kill -9 $pid; done
rm -rf /u01/app/ogg/oggma_first /u01/app/ogg/oggma_deploy

cd ${OGG_HOME}/bin
./oggca.sh -silent -responseFile  ~/scripts/oggsharding/oggca19.rsp HOST_SERVICEMANAGER=$server \
SERVER_WALLET=$WALLET_DIR/$server CLIENT_WALLET=$WALLET_DIR/dist_client





export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
export JAVA_HOME=$OGG_HOME/jdk
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$ORACLE_HOME/bin:$PATH

export OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
export OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH



export ORACLE_SID=$server

sqlplus / as sysdba <<EOF
drop user ggadmin cascade;
@$OGG_HOME/lib/sql/sharding/orashard_setup.sql A $server:9000/oggma_first Welcome1 $server:1521/$server;
EOF


export WALLET_DIR=$ORACLE_BASE/admin/wallet_dir
export CURL_CA_BUNDLE=$WALLET_DIR/root_ca
export CURL_CA_BUNDLE=$WALLET_DIR/rootCA_Cert.pem

curl -v -u   oggadmin:Welcome1 \
-H "Content-Type: application/json"   \
-H "Accept: application/json"   \
-X GET https://$server:9000/services/v2/deployments | jq


curl -v -u   oggadmin:Welcome1 \
-H "Content-Type: application/json"   \
-H "Accept: application/json"   \
-X GET https://$server:9000/services/v2/deployments/oggma_first | jq
#cd $OGG_HOME

#adminclient connect  https://shard1.sub06291314360.oggma.oraclevcn.com:9001 DEPLOYMENT  oggma_first as oggadmin password Welcome1
