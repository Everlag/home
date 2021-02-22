#!/bin/bash

set -e

# Secure our ssh keys which were copied in before this
 find /home/vagrant/.ssh/ -type f -name "id_*" ! -name "*.pub" \
 | xargs chmod 400

# Dependencies
# - git (newer version)
# - p7zip-full
# - node + npm
# - unzip
# - libgtk2.0-0 | libxss1 (for VS:Code)
# - i3 (Window manager) + i3status
# - rxvt-unicode (Terminal)
# - xinit (starting X)
# - xrdb (rxvt configuration)
# - suckless-tools (i3 demenu)
# - libanyevent-i3-perl (i3-save-tree)
# - mingetty (automatic login)
# - chromium-browser (chrome)
# - gconf2 (code dependency unsatisfied for 1.6)

# git
add-apt-repository -y ppa:git-core/ppa

# i3
# 
# NOTE: If keyring installation fails with 404,
# goto http://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/ and update
# the keyring file below and associated sha256
KEYRING_DEB=./keyring.deb
/usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2021.02.02_all.deb ${KEYRING_DEB} SHA256:cccfb1dd7d6b1b6a137bb96ea5b5eef18a0a4a6df1d6c0c37832025d2edaa710
dpkg -i ./${KEYRING_DEB}
echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" >> /etc/apt/sources.list.d/sur5r-i3.list
rm ${KEYRING_DEB}

# Actual installation
apt-get update
apt-get upgrade -y
apt-get install -y git p7zip-full libgtk2.0-0 libxss1 xinit gconf2 unzip
apt-get install --no-install-recommends -y i3 i3status mingetty
apt-get install -y rxvt-unicode x11-xserver-utils \
                    chromium-browser suckless-tools
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - # register node
apt-get install -y nodejs # npm now alongside nodejs... this changes... bleh
apt-get install -y build-essential dkms
# Previously, we installed npm and yarn here; npm likes to brick itself
# when run as root so we're not gonna do that...
apt-get update
apt-get upgrade -y
apt-get autoremove -y

# Install go
GO_VERSION=1.16
GO_TAR=go.tar.gz
wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz \
    -O ${GO_TAR} --quiet
tar -C /usr/local -xzf ${GO_TAR}
rm ${GO_TAR}

# Install more recent nano
#
# We compile from source as that's easiest
NANO_TAR=nano.tar.gz
wget https://www.nano-editor.org/dist/v2.8/nano-2.8.0.tar.gz \
    -O ${NANO_TAR} --quiet
tar -xzf ${NANO_TAR}
pushd nano-*
    # Specific build dependencies
    apt-get install -y libncurses5-dev libncursesw5-dev texinfo
    ./configure \
        --enable-utf8 --enable-color --enable-extra --enable-multibuffer
    make
    apt-get remove -y nano
    make install

    # Copy over our syntax files
    mkdir -p /usr/share/nano
    cp syntax/*.nanorc /usr/share/nano/
popd
rm -r nano-*
rm ${NANO_TAR}

# Remove default MOTD apart from knowing when we need to reboot
find /etc/update-motd.d ! -name '98-reboot-required' -type f -exec rm -f {} \;
find /etc/update-motd.d  -type l -delete

# Install vs code
# 
# This is an older version where --install-extension is known to work
# However, this version is very specific as it is the first which will
# set up an apt repository for us to update from.
CODE_DEB=vscode.deb
wget https://vscode-update.azurewebsites.net/1.10.2/linux-deb-x64/stable \
    -O ${CODE_DEB} --quiet
set +e
    dpkg -i ${CODE_DEB}
set -e
apt-get -f -y install
rm ${CODE_DEB}

# Create a script we'll run as our non-privileged user
bootstrapper=/home/vagrant/bootstrap.sh

# Declare our variables here to be filled in below
export GOPATH=/home/vagrant/gopath
export GOTO_SCRIPT=${GOPATH}/goto.sh
cat > ${bootstrapper} <<EOL
#!/bin/bash
set -e

# Fetch our configuration
git clone https://github.com/everlag/home /home/vagrant/home

# Setup our shell
pushd /home/vagrant
    rm ~/.bashrc
    rm ~/.profile

    pushd home
        ./link
    popd

    # Include GOPATH specific to this VM and GOBIN in PATH
    # NOTE: this should be the only unescaped replacement present here.
    echo "export GOPATH=${GOPATH}" >> /home/vagrant/.profile
    echo "export PATH=\$PATH:\$GOPATH/bin" >> /home/vagrant/.profile
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /home/vagrant/.profile
    cat <<EOT >> /home/vagrant/.profile
# A second time as GOPATH is now defined
if [ -n "\$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "\$HOME/.bashrc" ]; then
        . "\$HOME/.bashrc"
    fi
fi
EOT
popd

# Temporary directory for garbage
mkdir /home/vagrant/trash
# GOPATH
mkdir -p ${GOPATH}/src/github.com/Everlag
cat > ${GOTO_SCRIPT} <<EOF
#!/bin/bash
# Moves CWD to the usual root
# usage: . goto.sh
pushd /home/vagrant/gopath/src/github.com/Everlag
EOF
chmod +x ${GOTO_SCRIPT}

# update npm and install yarn
# 
# We do so here rather than outside since we absolutely want to
# be vagrant rather than root when this executes.
# https://github.com/nodesource/distributions/issues/1027
# sudo npm install -g npm yarn
# 
# I do not know how to update npm anymore :|
EOL
chmod +x ${bootstrapper}

# Run our bootstrapper as vagrant
su -c "cd ~ && ${bootstrapper}" vagrant

rm ${bootstrapper}