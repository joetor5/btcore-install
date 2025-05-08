# btcore-install

Install script for Bitcoin Core (https://bitcoincore.org/).

Works on macOS and GNU/Linux systems.

## License

Distributed under the MIT License. See the accompanying file LICENSE.

## Prerequisites

* Git
* cURL
* GnuPG
* OpenSSL


## Usage

```
git clone https://github.com/joetor5/bitcoin-core-install.git
cd bitcoin-core-install
chmod +x install.sh
./install.sh
```

The latest Bitcoin Core version will get installed by default. Optionally, a version number can be passed as an argument:

```
./install.sh 28.1
```
