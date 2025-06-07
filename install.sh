#!/usr/bin/env bash

# This software is part of btcore-install (https://github.com/joetor5/btcore-install)

#Copyright (c) 2025 Joel Torres
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

BTCORE_INSTALL_BRANCH="main"

if [[ -n $1 ]]; then
    if [[ $1 == "develop" || $1 == "main" ]]; then
        BTCORE_INSTALL_BRANCH=$1
    fi
fi

BTCORE_INSTALL_NAME="btcore-install"
BTCORE_INSTALL_BASE_URL="https://raw.githubusercontent.com/joetor5/btcore-install/$BTCORE_INSTALL_BRANCH"
BTCORE_INSTALL_SCRIPT_URL="$BTCORE_INSTALL_BASE_URL/btcore-install.sh"
BTCORE_INSTALL_VERSION_URL="$BTCORE_INSTALL_BASE_URL/.script_version"
BTCORE_INSTALL_LICENSE_URL="$BTCORE_INSTALL_BASE_URL/LICENSE"
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
        echo "Setting up $BTCORE_INSTALL_NAME environment..."
        mkdir -p $BTCORE_INSTALL_BIN
        exit_if_error "unable to create directories at $BTCORE_INSTALL_HOME"

        shell_rc_files=(~/.zshrc ~/.bashrc)
        for rc_file in "${shell_rc_files[@]}"
        do
            if [[ -f $rc_file ]]; then
                if [[ $(cat $rc_file | grep $BTCORE_INSTALL_NAME >/dev/null 2>&1; echo $?) != 0 ]]; then
                    echo 'if [[ -f $HOME/.btcore-install/.env ]]; then source $HOME/.btcore-install/.env; fi' >> $rc_file
                fi
            fi
        done

        echo $BTCORE_INSTALL_BRANCH > $BTCORE_INSTALL_HOME/.branch
        echo 'export PATH="$PATH:$HOME/.btcore-install/bin"' > $BTCORE_INSTALL_HOME/.env
        touch $BTCORE_INSTALL_HOME/.first-install

    fi
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

download_license () {

    curl -sSl -O --output-dir $BTCORE_INSTALL_HOME $BTCORE_INSTALL_LICENSE_URL
    exit_if_error "unable to download LICENSE file"

}

download_script () {

    curl -sSL -o $BTCORE_INSTALL_NAME --output-dir $BTCORE_INSTALL_BIN $BTCORE_INSTALL_SCRIPT_URL && \
    chmod +x $BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME
    exit_if_error "unable to install $BTCORE_INSTALL_NAME"

}

download_install () {

    echo "Downloading and installing $BTCORE_INSTALL_NAME..."
    download_license
    download_script

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
