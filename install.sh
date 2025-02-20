#!/bin/bash
# Copyright (c) 2024-2025 Joel Torres
# Distributed under the MIT software license, see the accompanying
# file LICENSE or https://opensource.org/license/mit.

VERSION=1.0

if [ $1 == "version" ]; then
    echo "Bitcoin Core Installer v$VERSION"
    exit 0
fi

fprint_i() {
    echo -e "\033[1m==> $1\033[0m"
}

fprint_e() {
    echo -e "\033[31;1m$1\033[0m"
}

fprint_s() {
    echo -e "\033[32;1m$1\033[0m"
}

PLATFORM_ARCH=$(uname -m)
if [ $(uname) == "Darwin" ]; then
    PLATFORM_NAME="apple-darwin"
    BITCOIN_DIR=$HOME'/Library/Application Support/Bitcoin'
elif [ $(uname) == "Linux" ]; then
    PLATFORM_NAME="linux-gnu"
    BITCOIN_DIR="$HOME/.bitcoin"
else
    fprint_e "Running script on unsupported platform, exiting"
    exit 1
fi

if [[ $SHELL == *"bash"* ]]; then
    SHRC="$HOME/.bashrc"
elif [[ $SHELL == *"zsh"* ]]; then
    SHRC="$HOME/.zshrc"
fi

CMD_DEPENDENCIES="git gpg curl openssl"
for cmd in $CMD_DEPENDENCIES
do
    if [ $(which $cmd >/dev/null 2>&1; echo $?) != 0 ]; then
        fprint_e "Command not found on path: $cmd, please install or add to path"
        exit 1
    fi
done

BITCOIN_CONFIG="$BITCOIN_DIR/bitcoin.conf"
BITCOIN_CORE_URL="https://bitcoincore.org"
BIN_URL="$BITCOIN_CORE_URL/bin"
DOWNLOAD_URL="$BITCOIN_CORE_URL/en/download/"
if [ -n "$1" ]; then
    VERSION_NUM=$1
    if [[ ! $VERSION_NUM =~ ^[0-9]{1,3}.[0-9]{1,3}$ ]]; then
        fprint_e "Error: invalid version number"
        exit 1
    fi
else
    VERSION_NUM=$(curl -s $DOWNLOAD_URL | grep "Latest version" | sed 's/.*Latest version: \([0-9]*\.[0-9]*\).*/\1/')
fi
VERSION_NUM_FULL="bitcoin-core-$VERSION_NUM"

KEYS_REPO="guix.sigs"
KEYS_REPO_URL="https://github.com/bitcoin-core/$KEYS_REPO"
KEYS_DIR="$KEYS_REPO/builder-keys"

is_bitcoin_core_running() {
    echo $(pgrep bitcoind >/dev/null 2>&1; echo $?)
}

start_bitcoin_core() {
    fprint_i "Starting bitcoind"
    bitcoind -daemon
}

download_bitcoin_core () {
    file_download_url="$BIN_URL/$VERSION_NUM_FULL/bitcoin-$VERSION_NUM-$PLATFORM_ARCH-$PLATFORM_NAME.tar.gz"
    bin_hash_url="$BIN_URL/$VERSION_NUM_FULL/SHA256SUMS"
    hash_sign_url="$bin_hash_url.asc"
    
    if [ ! -d $VERSION_NUM_FULL ]; then
        mkdir $VERSION_NUM_FULL
    fi

    for url in $file_download_url $bin_hash_url $hash_sign_url
    do
        fprint_i "Downloading $url"
        curl -O --output-dir $VERSION_NUM_FULL $url
    done

}

verify_bitcoin_core () {

    if [ ! -d $KEYS_REPO ]; then
        fprint_i "Downloading builder-keys ($KEYS_REPO_URL)"
        git clone $KEYS_REPO_URL
    else
        fprint_i "Updating builder-keys"
        git -C $KEYS_REPO pull
    fi
    
    fprint_i "Importing and refreshing keys"
    gpg --import $KEYS_DIR/*
    gpg --keyserver hkps://keys.openpgp.org --refresh-keys

    fprint_i "Verifying hashes and signatures"
    cd $VERSION_NUM_FULL
    shasum -a 256 --ignore-missing --check SHA256SUMS
    if [ $? != 0 ]; then
        fprint_e "Installation aborted: failure on computing hashes"
        exit 1
    fi

    touch .hash_verified

    good_sign_str="Good signature"
    good_sign_out=$(gpg --verify SHA256SUMS.asc 2> >(grep "$good_sign_str"))
    if [[ ! $good_sign_out == *"$good_sign_str"* ]]; then
        fprint_e "Installation aborted: no good gpg signatures found"
        exit 1
    fi
    echo "$good_sign_out"
    echo
    while true; do
        read -p "The above good signatures were found. Do you trust some of these? [y/n]: " answer
        case $answer in
            Y|y)
                touch .sign_verified; break;;
            N|n)
                fprint_e "Installation aborted: keys not trusted"; exit 1;;
        esac
    done

    cd ..
}

install_bitcoin_core () {
    fprint_i "Installing $VERSION_NUM_FULL"
    cd $VERSION_NUM_FULL
    tar xzf *.tar.gz

    if [ $(is_bitcoin_core_running) == 0 ]; then
        fprint_i "Stopping bitcoind before installing"
        bitcoin-cli stop
        sleep 5
    fi

    if [ $PLATFORM_NAME == "linux-gnu" ]; then
        sudo install -v -m 0755 -o root -g root -t /usr/local/bin bitcoin-$VERSION_NUM/bin/*
    elif [ $PLATFORM_NAME == "apple-darwin" ]; then
        if [ ! -d /usr/local/bin ]; then
            sudo mkdir -p /usr/local/bin
        fi
        sudo cp -v bitcoin-$VERSION_NUM/bin/bitcoin* /usr/local/bin/.
    fi

    if [ $? == 0 ]; then
        fprint_s "Bitcoin Core $VERSION_NUM successfully installed!"
        touch .installed
    else
        fprint_e "Installation aborted: error while installing"
        exit 1
    fi

    cd ..
    echo $VERSION_NUM > .version
}

init_bitcoin_core_config () {

    if [ ! -d "$BITCOIN_DIR" ]; then
        mkdir "$BITCOIN_DIR"
    fi

    if [ ! -e "$BITCOIN_CONFIG" ]; then
        fprint_i "Initializing Bitcoin Core config at $BITCOIN_CONFIG"
        echo "prune=2048" > "$BITCOIN_CONFIG"
        echo "maxconnections=50" >> "$BITCOIN_CONFIG"
        echo "server=1" >> "$BITCOIN_CONFIG"
        echo "rpcuser=$(whoami)" >> "$BITCOIN_CONFIG"
        echo "rpcpassword=$(openssl rand -base64 32 | tr = x)" >> "$BITCOIN_CONFIG"
    fi

    if [ $? == 0 ]; then
        fprint_i "Configuring ENV vars at $SHRC"
        if [ -z "$BITCOIN_RPC_USER" ]; then
            echo 'export BITCOIN_RPC_USER=$(grep rpcuser "'"$BITCOIN_CONFIG"'" | cut -d "=" -f 2)' >> $SHRC
        fi
        if [ -z "$BITCOIN_RPC_PASSWORD" ]; then
            echo 'export BITCOIN_RPC_PASSWORD=$(grep rpcpassword "'"$BITCOIN_CONFIG"'" | cut -d "=" -f 2)' >> $SHRC
        fi
    fi

     if [ $(crontab -l | grep "@reboot bitcoind -daemon" >/dev/null 2>&1; echo $?) != 0 ]; then
        fprint_i "Configuring crontab to start bitcoind at boot"
        crontab -l > crontab_tmp
        echo "@reboot bitcoind -daemon" >> crontab_tmp
        crontab crontab_tmp
        rm crontab_tmp
     fi

     touch .config_init

}

if [ -e .version ] && [ $(cat .version) != $VERSION_NUM ] && [ -d $VERSION_NUM_FULL ]; then
    rm $VERSION_NUM_FULL/.installed
fi

if [ -e $VERSION_NUM_FULL/.hash_verified ] &&
   [ -e $VERSION_NUM_FULL/.sign_verified ] &&
   [ -e $VERSION_NUM_FULL/.installed ]
then
        echo "Bitcoin Core $VERSION_NUM already installed"
        exit 0
fi

if [ ! -e $VERSION_NUM_FULL/.hash_verified ]; then download_bitcoin_core; fi
if [ ! -e $VERSION_NUM_FULL/.sign_verified ]; then verify_bitcoin_core; fi
if [ ! -e $VERSION_NUM_FULL/.installed ]; then install_bitcoin_core; fi
if [ ! -e .config_init ]; then init_bitcoin_core_config; fi
if [ ! $(is_bitcoin_core_running) == 0 ]; then start_bitcoin_core; fi
