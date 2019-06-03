# Oracle Settings
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=sharddirector
#export ORACLE_UNQNAME=shardcat
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=shardcat
#export PDB_NAME=pdb1
export DATA_DIR=/u01/app/oracle/oradata

export PATH=/usr/sbin:/usr/local/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/oracle/.local/bin:/home/oracle/bin
export PATH=$ORACLE_HOME/bin:$PATH

export LD_LIBRARY_PATH=/lib:/lib:/usr/lib
export CLASSPATH=/jlib:/rdbms/jlib
