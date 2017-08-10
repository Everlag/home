#!/bin/bash

set -e

# Dependencies
# - git
# - p7zip-full
# - node + npm
# - libgtk2.0-0 | libxss1 (for VS:Code)
apt-get update
apt-get upgrade -y
apt-get install -y git p7zip-full libgtk2.0-0 libxss1
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get install -y nodejs
apt-get install -y build-essential
npm install -g npm
apt-get update
apt-get upgrade -y
apt-get autoremove -y

# Install go
GO_VERSION=1.8.3
GO_TAR=go.tar.gz
wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz \
    -O ${GO_TAR} --quiet
tar -C /usr/local -xzf ${GO_TAR}
rm ${GO_TAR}

# Remove default MOTD apart from knowing when we need to reboot
find /etc/update-motd.d ! -name '98-reboot-required' -type f -exec rm -f {} \;
find /etc/update-motd.d  -type l -delete

# Install vs code
CODE_DEB=vscode.deb
wget https://go.microsoft.com/fwlink/?LinkID=760868 -O ${CODE_DEB} --quiet
set +e
    dpkg -i ${CODE_DEB}
set -e
apt-get -f -y install
rm ${CODE_DEB}

# Create a script we'll run as our non-privileged user
bootstrapper=/home/vagrant/bootstrap.sh
cat > ${bootstrapper} <<EOL
set -e

# Fetch our configuration
git clone https://github.com/everlag/home /home/vagrant/home

# Setup our shell
pushd /home/vagrant && \
rm ~/.bashrc && \
rm ~/.profile && \

cd home && ./link
popd

# Temporary directory for garbage
mkdir /home/vagrant/trash
# GOPATH
mkdir /home/vagrant/gopath
EOL
chmod +x ${bootstrapper}

# Run our bootstrapper as vagrant
su -c "cd ~ && ${bootstrapper}" vagrant

rm ${bootstrapper}