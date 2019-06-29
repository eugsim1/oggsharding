sudo su 
echo "opc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

setenforce Permissive
getenforce
setenforce 0
systemctl stop firewalld
systemctl  disable firewalld


sudo yum install -y oracle-database-preinstall-19c
sudo yum groupinstall 'Server with GUI' -y
sudo yum install tigervnc-server -y
sudo systemctl set-default graphical.target


 
echo "Toula1412#" | passwd --stdin oracle
cp -R /home/opc/.ssh /home/oracle
cd /home/oracle/.ssh
chown -R oracle:oinstall /home/oracle
su - oracle
mkdir /home/oracle/scripts
cd /home/oracle/scripts
sudo yum install -y git
rm -rf oggsharding
git clone https://github.com/eugsim1/oggsharding.git


### vnc server setup
#sudo cp /lib/systemd/system/vncserver@.service /lib/systemd/system/vncserver@:3.service
#sudo vi  /lib/systemd/system/vncserver@:3.service
cd /lib/systemd/system/
# wget https://github.com/eugsim1/oggsharding/blob/master/vncserver%40_3.service
sudo cp ~/scripts/oggsharding/vncserver@_3.service /lib/systemd/system/vncserver@:3.service
mkdir -p /home/oracle/.vnc/
#mkdir -p /home/opc/.vnc/
echo oracle | vncpasswd -f > /home/oracle/.vnc/passwd
chown -R oracle:oinstall /home/oracle/.vnc
chmod 0600 /home/oracle/.vnc/passwd
#echo oracle | vncpasswd -f > /home/opc/.vnc/passwd


sudo systemctl daemon-reload
sudo systemctl enable vncserver@:3.service
sudo systemctl start vncserver@:3.service
####
