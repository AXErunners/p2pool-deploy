#!/bin/bash
# Author: Chris Har
# Author: AXErunners
#
# Thanks to all who published information on the Internet!
#
# Disclaimer: Your use of this script is at your sole risk.
# This script and its related information are provided "as-is", without any warranty,
# whether express or implied, of its accuracy, completeness, fitness for a particular
# purpose, title or non-infringement, and none of the third-party products or information
# mentioned in the work are authored, recommended, supported or guaranteed by The Author.
# Further, The Author shall not be liable for any damages you may sustain by using this
# script, whether direct, indirect, special, incidental or consequential, even if it
# has been advised of the possibility of such damages.
#
# NOTE:
# This script is based on:
# - Git Commit: 18dc987 => https://github.com/dashpay/p2pool-dash
# - Git Commit: 20bacfa => https://github.com/dashpay/dash
#
# You may have to perform your own validation / modification of the script to cope with newer
# releases of the above software.
#
# Tested with Ubuntu 17.10

# # # # # # # # # # # # # # # # # # # # # #
# Variables:
# UPDATE THEM TO MATCH YOUR SETUP !!!

PUBLIC_IP=
EMAIL=
PAYOUT_ADDRESS=
USER_NAME=axerunner
RPCUSER=
RPCPASSWORD=

# # # # # # # # # # # # # # # # # # # # # #

#
#
#

FEE=0.9
DONATION=0.0
AXE_WALLET_URL=https://github.com/AXErunners/axe/releases/download/v1.1.3/axecore-1.1.3-linux64.tar.gz
AXE_WALLET_ZIP=axecore-1.1.3-linux64.tar.gz
AXE_WALLET_LOCAL=axecore-1.1.3
P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

# Enable 2G swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo swapon --show

#
# Install Prerequisites
#

cd ~
sudo apt-get update
sudo apt-get --yes install python3 python-zope.interface python-twisted python-twisted-web python-dev gcc g++ git libboost-all-dev bsdmainutils
sudo apt-get --yes install python-virtualenv virtualenv fail2ban ufw build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev 

# Firewall
sudo ufw allow ssh/tcp
sudo ufw allow 9937/tcp
sudo ufw allow 9337/tcp
sudo ufw allow 7903/tcp
sudo ufw allow 8999/tcp
sudo ufw logging on
sudo ufw disable
sudo ufw enable
sudo apt-get update
sudo apt-get upgrade -y

#
# Get latest p2pool-AXE
#
EOT
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

mkdir git
cd git
git clone https://github.com/AXErunners/p2pool-axe
cd p2pool-axe
sudo apt-get update
git submodule init
git submodule update
cd axe_hash
sudo python setup.py install --user

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
# Prepare AXE configuration
#

mkdir ~/.axecore
cat <<EOT >> ~/.axecore/axe.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
alertnotify=echo %s | mail -s "AXE Alert" $EMAIL
server=1
daemon=1
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
#sudo ln -s /home/$USER_NAME/git/axe/contrib/init/axed.service axed.service
#sudo sed -i 's/User=axecore/User='"$USER_NAME"'/g' axed.service
#sudo sed -i 's/Group=axecore/Group='"$USER_NAME"'/g' axed.service
#sudo sed -i 's/\/var\/lib\/axed/\/home\/'"$USER_NAME"'\/.axecore/g' axed.service
#sudo sed -i 's/\/etc\/axecore\/axe.conf/\/home\/'"$USER_NAME"'\/.axecore\/axe.conf/g' axed.service
#sudo systemctl daemon-reload
#sudo systemctl enable axed
#sudo service axed start
axed

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
