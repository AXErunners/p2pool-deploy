# p2pool-axe-deploy
### Installation
```
adduser axerunner
usermod -aG sudo axerunner
su axerunner
cd ~
git clone https://github.com/axerunners/p2pool-axe-deploy
nano ./p2pool-axe-deploy/p2pool.deploy.sh # edit the script to match your setup
bash ./p2pool-axe-deploy/p2pool.deploy.sh
```
### Start
```
axed
bash ~/p2pool.start.sh
```
