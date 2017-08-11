#!/bin/bash

set -e

# Secure our ssh keys which were copied in before this
 find /home/vagrant/.ssh/ -type f -name "id_*" ! -name "*.pub" \
 | xargs chmod 400

# Dependencies
# - git (newer version)
# - p7zip-full
# - node + npm
# - libgtk2.0-0 | libxss1 (for VS:Code)
# - i3 (Window manager) + i3status
# - rxvt-unicode (Terminal)
# - xinit (starting X)
# - xrdb (rxvt configuration)
# - mingetty (automatic login)
add-apt-repository -y ppa:git-core/ppa
apt-get update
apt-get upgrade -y
apt-get install -y git p7zip-full libgtk2.0-0 libxss1 xinit
apt-get install --no-install-recommends -y i3 i3status mingetty
apt-get install -y rxvt-unicode x11-xserver-utils
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
CODE_DEB=vscode.deb
wget https://go.microsoft.com/fwlink/?LinkID=760868 -O ${CODE_DEB} --quiet
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

    # Include GOPATH specific to this VM
    echo "export GOPATH=${GOPATH}" >> /home/vagrant/.profile
popd

# Temporary directory for garbage
mkdir /home/vagrant/trash
# GOPATH
mkdir -p ${GOPATH}/src/github.com/Everlag
cat > ${GOTO_SCRIPT} <<EOF
#!/bin/bash
# Moves CWD to the usual root
# usage: . goto.sh
pushd src/github.com/Everlag
EOF
chmod +x ${GOTO_SCRIPT}

EOL
chmod +x ${bootstrapper}

# Run our bootstrapper as vagrant
su -c "cd ~ && ${bootstrapper}" vagrant

rm ${bootstrapper}