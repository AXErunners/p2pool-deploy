# p2pool-axe-deploy
### Installation
```
adduser axerunner && usermod -aG sudo axerunner
su axerunner
cd ~
git clone https://github.com/charlesrocket/p2pool-axe-deploy
nano ./p2pool-axe-deploy/p2pool.deploy.sh #edit the deployment script to match your node's setup
bash ./p2pool-axe-deploy/p2pool.deploy.sh
```
### Start
```
axed
bash ~/p2pool.start.sh
```
