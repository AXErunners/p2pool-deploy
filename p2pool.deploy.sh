
#AXErunners

#Grab test parameters and local IP
IP=`ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'`
PUBLIC_IP=$IP
EMAIL=foo
PAYOUT_ADDRESS=PUGsuNFjxPujFito8LCcd8stir7qYG4tKb
USER_NAME=axecore
RPCUSER=axerunner-test-13
RPCPASSWORD=notgoodenough

FEE=0.9
DONATION=0.0
AXE_WALLET_URL=https://github.com/AXErunners/axe/releases/download/v1.1.3/axecore-1.1.3-linux64.tar.gz
AXE_WALLET_ZIP=axecore-1.1.3-linux64.tar.gz
AXE_WALLET_LOCAL=axecore-1.1.3
P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

#Add user and group
sudo adduser --disabled-password --gecos "" $USER_NAME
sudo usermod -aG sudo $USER_NAME
sudo su $USER_NAME

# Enable 2G swap
swapsize=2048
grep -q "swapfile" /etc/fstab
if [ $? -ne 0 ]; then
  echo 'Adding swapfile.'
  fallocate -l ${swapsize}M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
  echo 'Swapfile already enabled.'
fi

#
# Install Prerequisites
#

cat << "EOF"
    ______     __  __     ______
   /\  __ \   /\_\_\_\   /\  ___\
   \ \  __ \  \/_/\_\/_  \ \  __\
    \ \_\ \_\   /\_\/\_\  \ \_____\
     \/_/\/_/   \/_/\/_/   \/_____/
 ______     ______     ______     ______
/\  ___\   /\  __ \   /\  == \   /\  ___\
\ \ \____  \ \ \/\ \  \ \  __<   \ \  __\
 \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\
  \/_____/   \/_____/   \/_/ /_/   \/_____/

EOF
cd ~
sudo apt-get --yes install fail2ban python-zope.interface python-twisted python-twisted-web python-dev gcc g++ git libncurses-dev libboost-all-dev
sudo apt-get --yes install python-virtualenv virtualenv build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils

# Firewall
sudo ufw allow 9937/tcp
sudo ufw allow 9337/tcp
sudo ufw allow 7903/tcp
sudo ufw allow 8999/tcp

#
# Get latest p2pool-AXE
#

mkdir git
cd git
git clone https://github.com/AXErunners/p2pool-axe
cd p2pool-axe
sudo apt-get update
git submodule init
git submodule update
cd axe_hash
python setup.py install --user

#
# Install Web Frontends
#

cd ..
mv web-static web-static.old
git clone $P2POOL_FRONTEND web-static
mv web-static.old web-static/legacy
cd web-static
git clone $P2POOL_FRONTEND2 status
git clone $P2POOL_FRONTEND3 ext

#
# TO DO - Get specific version of AXE wallet for Linux
#

#cd ~
#mkdir axe
#cd axe
#wget $AXE_WALLET_URL
#tar -xvzf $AXE_WALLET_ZIP
#rm $AXE_WALLET_ZIP

#
# Prepare AXE configuration
#

mkdir ~/.axecore
cat <<EOT >> ~/.axecore/axe.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
alertnotify=echo %s | mail -s "AXE Alert" $EMAIL
listen=1
server=1
daemon=1
rpcallowip=127.0.0.1
EOT

#
# Get latest AXE core and its dependencies
#

cd ~/git
git clone https://github.com/AXErunners/axe
sudo apt-get update
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install --yes libdb4.8-dev libdb4.8++-dev
sudo apt-get install --yes libminiupnpc-dev libzmq3-dev
cd axe
./autogen.sh && ./configure --without-gui && make && sudo make install

#
# TO DO - Install AXE daemon service and set to Auto Start
#

cd /etc/systemd/system
sudo ln -s /home/$USER_NAME/git/axe/contrib/init/axed.service axed.service
sudo sed -i 's/User=axecore/User='"$USER_NAME"'/g' axed.service
sudo sed -i 's/Group=axecore/Group='"$USER_NAME"'/g' axed.service
sudo sed -i 's/\/var\/lib\/axed/\/home\/'"$USER_NAME"'\/.axecore/g' axed.service
sudo sed -i 's/\/etc\/axecore\/axe.conf/\/home\/'"$USER_NAME"'\/.axecore\/axe.conf/g' axed.service
sudo systemctl daemon-reload
sudo systemctl enable axed
sudo service axed start
echo

#
# Prepare p2pool startup script
#

cat <<EOT >> ~/p2pool.start.sh
python ~/git/p2pool-axe/run_p2pool.py --external-ip $PUBLIC_IP -f $FEE --give-author $DONATION -a $PAYOUT_ADDRESS
EOT

if [ $? -eq 0 ]
then
echo
echo Installation completed!
echo You can start p2pool instance by command:
echo
echo bash ~/p2pool.start.sh
echo
echo NOTE: you will need to wait until AXE daemon has finished
echo blockchain synchronization before the p2pool instance is usable.
echo
fi
