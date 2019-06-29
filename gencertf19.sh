
source ~/scripts/oggsharding/ora19.env
export WALLET_DIR=$ORACLE_BASE/admin/wallet_dir
export SHARDIND_WALLET_DIR=$ORACLE_BASE/admin/ggshd_wallet
cd $ORACLE_BASE/admin	
rm -rf 	$ORACLE_BASE/admin/ggshd_wallet $ORACLE_BASE/admin/wallet_dir
mkdir -p $ORACLE_BASE/admin/ggshd_wallet
mkdir -p $ORACLE_BASE/admin/wallet_dir

cd $ORACLE_BASE/admin
serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

if [[ $server == "sharddirector" ]]
 then 
  orapki wallet create -wallet  $WALLET_DIR/root_ca -pwd Welcome1  -auto_login
  orapki wallet add -wallet $WALLET_DIR/root_ca -dn "CN=RootCA" -keysize 2048 -self_signed -validity 7300 -pwd Welcome1
  orapki wallet export -wallet $WALLET_DIR/root_ca  -dn "CN=RootCA" -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
  tar -cvf wallet_dir.tar wallet_dir
  scp wallet_dir.tar shard1:/$ORACLE_BASE/admin/
  scp wallet_dir.tar shard2:/$ORACLE_BASE/admin/
 else
  cd $ORACLE_BASE/admin
  tar -xvf wallet_dir.tar
fi

## create server certificate for the host
orapki wallet create -wallet $WALLET_DIR/$server -auto_login -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/$server -dn "CN=$server" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $WALLET_DIR/$server -pwd Welcome1  -dn "CN=$server"  -request $WALLET_DIR/${server}_req.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $WALLET_DIR/${server}_req.pem -cert $WALLET_DIR/${server}_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/$server -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/$server -user_cert  -cert $WALLET_DIR/${server}_Cert.pem -pwd Welcome1
### create a distribution server user certificate
orapki wallet create -wallet $WALLET_DIR/dist_client -auto_login -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -dn "CN=$server" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $WALLET_DIR/dist_client -pwd Welcome1  -dn "CN=$server"  -request $WALLET_DIR/dist_client_req.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $WALLET_DIR/dist_client_req.pem -cert $WALLET_DIR/dist_client_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $WALLET_DIR/dist_client -user_cert  -cert $WALLET_DIR/dist_client_Cert.pem -pwd Welcome1
### display wallet configuration
orapki wallet display -wallet $WALLET_DIR -pwd Welcome1
orapki wallet display -wallet $WALLET_DIR/root_ca -pwd Welcome1
orapki wallet display -wallet $WALLET_DIR/$server -pwd Welcome1
orapki wallet display -wallet $WALLET_DIR/dist_client


## create wallets
export WALLET_DIR=$ORACLE_BASE/admin/wallet_dir
export SHARDIND_WALLET_DIR=$ORACLE_BASE/admin/ggshd_wallet
orapki wallet create -wallet $SHARDIND_WALLET_DIR -pwd Welcome1  -auto_login
orapki wallet add -wallet $SHARDIND_WALLET_DIR -dn "CN=dist_client" -keysize 2048 -pwd Welcome1
orapki wallet export -wallet $SHARDIND_WALLET_DIR -pwd Welcome1  -dn "CN=dist_client"  -request $SHARDIND_WALLET_DIR/dist_client.pem
orapki cert create -wallet $WALLET_DIR/root_ca -request $SHARDIND_WALLET_DIR/dist_client.pem -cert $SHARDIND_WALLET_DIR/dist_client_Cert.pem -serial_num 20 -validity 365 -pwd Welcome1
orapki wallet add -wallet $SHARDIND_WALLET_DIR -trusted_cert -cert $WALLET_DIR/rootCA_Cert.pem -pwd Welcome1
orapki wallet add -wallet $SHARDIND_WALLET_DIR -user_cert  -cert $SHARDIND_WALLET_DIR/dist_client_Cert.pem -pwd Welcome1
orapki wallet display -wallet $SHARDIND_WALLET_DIR


source ~/scripts/oggsharding/ogg19.env

serverFQDN=`hostname -f` 
server=$(echo $serverFQDN | sed 's/\..*//')
echo $server

for pid in $(ps -ef | grep "oggma" | awk '{print $2}');  do kill -9 $pid; done

rm -rf /u01/app/ogg/oggma_first /u01/app/ogg/oggma_deploy
cd ${OGG_HOME}/bin
./oggca.sh -silent -responseFile /home/oracle/ogg19.rsp HOST_SERVICEMANAGER=$server \
SERVER_WALLET=/u01/app/oracle/admin/wallet_dir/$server

