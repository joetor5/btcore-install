#!/bin/bash
# Copyright (c) 2024 Joel Torres
# Distributed under the MIT software license, see the accompanying
# file LICENSE or https://opensource.org/license/mit.


PLATFORM_ARCH=$(uname -m)
if [ $(uname) == "Darwin" ]; then
    PLATFORM_NAME="apple-darwin"
    BITCOIN_DIR=$HOME'/Library/Application Support/Bitcoin'
elif [ $(uname) == "Linux" ]; then
    PLATFORM_NAME="linux-gnu"
    BITCOIN_DIR="$HOME/.bitcoin"
else
    echo "Running script on unsupported platform, exiting"
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
    if [ $(which $cmd >/dev/null; echo $?) != 0 ]; then
        echo -e "Command not found on path: \033[31;1m$cmd\033[0m, please install or add to path"
        exit 1
    fi
done

BITCOIN_CONFIG="$BITCOIN_DIR/bitcoin.conf"
BITCOIN_CORE_URL="https://bitcoincore.org"
BIN_URL="$BITCOIN_CORE_URL/bin"
DOWNLOAD_URL="$BITCOIN_CORE_URL/en/download/"
VERSION_NUM=$(curl -s $DOWNLOAD_URL | grep "Latest version" | sed 's/.*Latest version: \([0-9]*\.[0-9]*\).*/\1/')
VERSION_NUM_FULL="bitcoin-core-$VERSION_NUM"

KEYS_REPO="guix.sigs"
KEYS_REPO_URL="https://github.com/bitcoin-core/$KEYS_REPO"
KEYS_DIR="$KEYS_REPO/builder-keys"


function download_bitcoin_core {
    file_download_url="$BIN_URL/$VERSION_NUM_FULL/bitcoin-$VERSION_NUM-$PLATFORM_ARCH-$PLATFORM_NAME.tar.gz"
    bin_hash_url="$BIN_URL/$VERSION_NUM_FULL/SHA256SUMS"
    hash_sign_url="$bin_hash_url.asc"
    
    if [ ! -d $VERSION_NUM_FULL ]; then
        mkdir $VERSION_NUM_FULL
    fi

    for url in $file_download_url $bin_hash_url $hash_sign_url
    do
        echo -e "\033[1m==> Downloading $url\033[0m"
        curl -O --output-dir $VERSION_NUM_FULL $url
    done

}

function verify_bitcoin_core {

    if [ ! -d $KEYS_REPO ]; then
        echo -e "\033[1m==> Downloading builder-keys ($KEYS_REPO_URL)\033[0m"
        git clone $KEYS_REPO_URL
    else
        echo -e "\033[1m==> Updating builder-keys\033[0m"
        git -C $KEYS_REPO pull
    fi
    
    echo -e "\033[1m==> Importing and refreshing keys\033[0m"
    gpg --import $KEYS_DIR/*
    gpg --keyserver hkps://keys.openpgp.org --refresh-keys

    echo -e "\033[1m==> Verifying hashes and signatures\033[0m"
    cd $VERSION_NUM_FULL
    shasum -a 256 --ignore-missing --check SHA256SUMS
    if [ $? != 0 ]; then
        echo -e "\033[31;1mInstallation aborted: failure on computing hashes\033[0m"
        exit 1
    fi

    touch .hash_verified

    good_sign_str="Good signature"
    good_sign_out=$(gpg --verify SHA256SUMS.asc 2> >(grep "$good_sign_str"))
    if [[ ! $good_sign_out == *"$good_sign_str"* ]]; then
        echo -e "\033[31;1mInstallation aborted: no good gpg signatures found\033[0m"
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
                echo -e "\033[31;1mInstallation aborted: keys not trusted\033[0m"; exit 1;;
        esac
    done

    cd ..
}

function install_bitcoin_core {
    echo -e "\033[1m==> Installing $VERSION_NUM_FULL\033[0m"
    cd $VERSION_NUM_FULL
    tar xzf *.tar.gz

    if [ $PLATFORM_NAME == "linux-gnu" ]; then
        sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-$VERSION_NUM/bin/*
    elif [ $PLATFORM_NAME == "apple-darwin" ]; then
        if [ ! -d /usr/local/bin ]; then
            sudo mkdir -p /usr/local/bin
        fi
        sudo cp bitcoin-$VERSION_NUM/bin/bitcoin* /usr/local/bin/.
    fi

    if [ $? == 0 ]; then
        echo -e "\033[32;1mBitcoin Core $VERSION_NUM successfully installed!\033[0m"
        touch .installed
    else
        echo -e "\033[31;1mInstallation aborted: error while installing\033[0m"
        exit 1
    fi

    cd ..
}

function init_bitcoin_core_config {

    if [ ! -d "$BITCOIN_DIR" ]; then
        mkdir "$BITCOIN_DIR"
    fi

    if [ ! -e "$BITCOIN_CONFIG" ]; then
        echo -e "\033[1m==> Initializing Bitcoin Core config at $BITCOIN_CONFIG\033[0m"
        echo "prune=2048" > "$BITCOIN_CONFIG"
        echo "server=1" >> "$BITCOIN_CONFIG"
        echo "rpcuser=$(whoami)" >> "$BITCOIN_CONFIG"
        echo "rpcpassword=$(openssl rand -base64 32)" >> "$BITCOIN_CONFIG"
    fi

    if [ $? == 0 ]; then
        echo -e "\033[1m==> Configuring ENV vars at $SHRC\033[0m"
        if [ -z "$BITCOIN_RPC_USER" ]; then
            echo 'export BITCOIN_RPC_USER=$(grep rpcuser "'"$BITCOIN_CONFIG"'" | cut -d "=" -f 2)' >> $SHRC
        fi
        if [ -z "$BITCOIN_RPC_PASSWORD" ]; then
            echo 'export BITCOIN_RPC_PASSWORD=$(grep rpcpassword "'"$BITCOIN_CONFIG"'" | cut -d "=" -f 2)' >> $SHRC
        fi
    fi

     crontab -l | grep "@reboot bitcoind -daemon" > /dev/null
     if [ $? != 0 ]; then
        echo -e "\033[1m==> Configuring crontab to start bitcoind at boot\033[0m"
        crontab -l > crontab_tmp
        echo "@reboot bitcoind -daemon" >> crontab_tmp
        crontab crontab_tmp
        rm crontab_tmp
     fi

     touch .config_init

}

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
