#!/usr/bin/env bash
# Copyright (c) 2025 Joel Torres
# Distributed under the MIT License. See the accompanying file LICENSE.

if [[ -n $1 && $1 == "dev" ]]; then
    BTCORE_INSTALL_BRANCH="develop"
else
    BTCORE_INSTALL_BRANCH="main"
fi

BTCORE_INSTALL_NAME="btcore-install"
BTCORE_INSTALL_BASE_URL="https://raw.githubusercontent.com/joetor5/btcore-install"
BTCORE_INSTALL_SCRIPT_URL="$BTCORE_INSTALL_BASE_URL/$BTCORE_INSTALL_BRANCH/btcore-install.sh"
BTCORE_INSTALL_VERSION_URL="$BTCORE_INSTALL_BASE_URL/$BTCORE_INSTALL_BRANCH/.script_version"
BTCORE_INSTALL_HOME="$HOME/.$BTCORE_INSTALL_NAME"
BTCORE_INSTALL_BIN="$BTCORE_INSTALL_HOME/bin"
BTCORE_INSTALL_SCRIPT="$BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME"

exit_if_error () {
    if [[ $? != 0 ]]; then
        echo -e "\033[31;1mError: $1\033[0m"
        exit 1
    fi
}

setup_environment () {
    
    if [[ ! -d "$BTCORE_INSTALL_HOME" ]]; then
        echo "Setting up $BTCORE_INSTALL_NAME directories..."
        mkdir -p $BTCORE_INSTALL_BIN
        exit_if_error "unable to create directories at $BTCORE_INSTALL_HOME"
        touch $BTCORE_INSTALL_HOME/.first-install
    fi

    shell_rc_files=(~/.zshrc ~/.bashrc)
    for rc_file in "${shell_rc_files[@]}"
    do
        if [[ -f $rc_file ]]; then
            if [[ $(cat $rc_file | grep "$BTCORE_INSTALL_NAME" >/dev/null 2>&1; echo $?) != 0 ]]; then
                echo "Adding $BTCORE_INSTALL_NAME to PATH on $rc_file"
                echo 'export PATH="$PATH:$HOME/.btcore-install/bin"' >> $rc_file
            fi
        fi
    done
}

check_latest_version () {

    if [[ -f $BTCORE_INSTALL_SCRIPT ]]; then
        echo "Checking the latest $BTCORE_INSTALL_NAME version..."
        latest_version=$(curl -sSL $BTCORE_INSTALL_VERSION_URL)
        installed_version=$($BTCORE_INSTALL_SCRIPT -v)
        if [[ $latest_version == $installed_version  ]]; then
            echo "Latest version ($latest_version) installed, nothing to update."
            exit 0
        fi
    fi
}

download_install () {

    echo "Downloading and installing $BTCORE_INSTALL_NAME..."
    curl -sSL -o $BTCORE_INSTALL_NAME --output-dir $BTCORE_INSTALL_BIN $BTCORE_INSTALL_SCRIPT_URL && \
    chmod +x $BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME
    exit_if_error "unable to install $BTCORE_INSTALL_NAME"
    
    success_msg="Success!"
    if [[ -f $BTCORE_INSTALL_HOME/.first-install ]]; then
        success_msg="$success_msg Restart your terminal to start using."
        rm $BTCORE_INSTALL_HOME/.first-install
    fi

    echo -e "\033[32;1m$success_msg\033[0m"
}


install () {
    setup_environment
    check_latest_version
    download_install
}

install
