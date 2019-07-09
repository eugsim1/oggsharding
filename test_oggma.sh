serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

export ORACLE_HOSTNAME=$server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=$server
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib
export ORACLE_HOME PATH ORACLE_SID TNS_ADMIN LD_LIBRARY_PATH
export  OGG_HOME=/u01/app/ogg/oggma
export  OGG_BIN=/u01/app/ogg/oggbin
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$ORACLE_HOME/bin:$PATH
export JAVA_HOME=/u01/app/ogg/oggma/jdk
OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME


export ORA_INVENTORY=/u01/app/oraInventory
export TNS_ADMIN=${ORACLE_HOME}/network/admin

export OGG_BASE=/u01/app/ogg
export OGG_HOME=/u01/app/ogg/oggma
export OGG_BIN=/u01/app/ogg/oggbin
export JAVA_HOME=$OGG_HOME/jdk
export PATH=$OGG_HOME/bin:$OGG_HOME/jdk/bin:$ORACLE_HOME/bin:$PATH

OGG_ETC_HOME=/u01/app/ogg/oggma_first/etc
OGG_VAR_HOME=/u01/app/ogg/oggma_first/var
export OGG_HOME OGG_ETC_HOME OGG_VAR_HOME

echo "test deployment "  
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
