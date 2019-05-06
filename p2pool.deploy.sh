#!/bin/bash
# Author: Chris Har, AXErunners
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
#
# Variables
# UPDATE THEM TO MATCH YOUR SETUP !!
#
PUBLIC_IP=<your public IP address>
EMAIL=<your email address>
PAYOUT_ADDRESS=<your AXE wallet address to receive fees>
USER_NAME=<linux user name>
RPCUSER=<your random rpc user name>
RPCPASSWORD=<your random rpc password>

FEE=0.5
DONATION=0.5
AXE_WALLET_URL=https://github.com/AXErunners/axe/releases/download/v1.3.1.1/axecore-1.3.1.1-x86_64-linux-gnu.tar.gz
AXE_WALLET_ZIP=axecore-1.3.1.1-x86_64-linux-gnu.tar.gz
AXE_WALLET_LOCAL=axecore-1.3.1.1
P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

#
# Install Prerequisites
#
cd ~
sudo apt-get --yes install python-zope.interface python-twisted python-twisted-web python-dev
sudo apt-get --yes install gcc g++
sudo apt-get --yes install git

#
# Get latest p2pool-axe
#
mkdir git
cd git
git clone https://github.com/axerunners/p2pool-axe
cd p2pool-axe
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
# Get specific version of AXE wallet for Linux
#
cd ~
mkdir axe
cd axe
wget $AXE_WALLET_URL
tar -xvzf $AXE_WALLET_ZIP
rm $AXE_WALLET_ZIP

#
# Copy AXE daemon
#
sudo cp ~/axe/$AXE_WALLET_LOCAL/bin/axed /usr/bin/axed
sudo cp ~/axe/$AXE_WALLET_LOCAL/bin/axe-cli /usr/bin/axe-cli
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/axed
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/axe-cli

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
# Get latest AXE core
#
cd ~/git
git clone https://github.com/axerunners/axe

#
# Install AXE daemon service and set to Auto Start
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

#
# Prepare p2pool startup script
#
cat <<EOT >> ~/p2pool.start.sh
python ~/git/p2pool-axe/run_p2pool.py --external-ip $PUBLIC_IP -f $FEE --give-author $DONATION -a $PAYOUT_ADDRESS
EOT

if [ $? -eq 0 ]
then
echo
echo Installation Completed.
echo You can start p2pool instance by command:
echo
echo bash ~/p2pool.start.sh
echo
echo NOTE: you will need to wait until AXE daemon has finished
echo blockchain synchronization before the p2pool instance is usable.
echo
fi
