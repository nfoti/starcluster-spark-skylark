#!/usr/bin/env bash

# NB: if you got this off github, the sge.tar.gz file is stored in the LFS
# system, so you need to install git-lfs, delete this repo, and redownload the
# repo to get the actual file (otherwise you just get a text pointer)

# Instructions:
# open a fresh Ubuntu Vivid AMI (or Trusty for 14.04)
# copy this file, sge.tar.gz, cleanup.py, and scimage_14.04.py to ~
# edit /etc/apt/sources.list first to enable multiverse for Vivid, not
# necessary for trusty obviously
# then run this file from ~
# save this instance as a new starcluster compatible AMI


sudo apt-get -y update; sudo apt-get -y upgrade
sudo apt-get -y install nfs-kernel-server nfs-common portmap
sudo ln -s /etc/init.d/nfs-kernel-server /etc/init.d/nfs
sudo ln -s /lib/systemd/system/nfs-kernel-server.service /lib/systemd/system/nfs.service
mkdir starclustersetup
cp scimage_14.04.py starclustersetup
cd starclustersetup
chmod 764 scimage_14.04.py
sudo python scimage_14.04.py
sudo service apache2 stop
sudo apt-get -y install nginx-core nginx
cd ..
sudo apt-get -y install upstart # for some reason this is missing!
echo 'echo "service portmap \$1" > /etc/init.d/portmap' | sudo bash
sudo chmod 755  /etc/init.d/portmap

# Useful for managing Python/R environments with conda
pip install autoenv

## Install some math libraries
curl -L -o Eigen-3.2.7.tar.gz http://bitbucket.org/eigen/eigen/get/3.2.7.tar.gz
tar xvzf Eigen-3.2.7.tar.gz
mv eigen-eigen-b30b87236a1b/Eigen /usr/local/include
rm -rf eigen-eigen-b30b87236a1b
rm Eigen-3.2.7.tar.gz
sudo apt-get -y install libarmadillo-dev
sudo apt-get -y install libboost-dev
sudo apt-get -y install libgsl0ldbl

# Miniconda (for Python 2 and 3)
curl -O https://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
bash Miniconda-latest-Linux-x86_64.sh -b -p /usr/local/miniconda
rm Miniconda-latest-Linux-x86_64.sh
curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh 
bash Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3
rm Miniconda3-latest-Linux-x86_64.sh

# git-lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
apt-get -y install git-lfs

cd /opt
sudo rm -rf ./sge6-fresh
cd
mkdir sge
cp sge.tar.gz ./sge
cd sge
tar -xvsf sge.tar.gz
sudo cp -r sge6-fresh /opt
cd

# Clean up so that we can bake an AMI
rm -r sge starclustersetup
rm sge.tar.gz scimage_14.04.py
rm doall.sh
sudo apt-get -y autoremove
sudo apt-get -y autoclean
python cleanup.py
rm -f cleanup.py
