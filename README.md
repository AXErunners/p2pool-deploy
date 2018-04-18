# p2pool-axe-deploy
### Installation
```
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
nano /etc/fstab
```
add following line in the end of the file `/swapfile none swap sw 0 0`
```
adduser axerunner
usermod -aG sudo axerunner
su axerunner
cd ~
git clone https://github.com/charlesrocket/p2pool-axe-deploy
nano ./p2pool-axe-deploy/p2pool.deploy.sh #edit the deployment script to match setup
bash ./p2pool-axe-deploy/p2pool.deploy.sh
```

### Start
`bash ~/p2pool.start.sh`
