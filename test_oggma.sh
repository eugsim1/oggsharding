


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
