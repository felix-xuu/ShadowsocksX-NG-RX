#!/bin/sh

#  install.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`

APP_DIR="$HOME/Library/Application Support/ShadowsocksX-NG-RX"
rm -f "$APP_DIR/$1"
rm -rf $HOME/Library/Application\ Support/ShadowsocksX-NG-RX/$1-*
mkdir -p "$APP_DIR/$1-$2"
cp -f $1 "$APP_DIR/$1-$2/"
ln -s "$APP_DIR/$1-$2/$1" "$APP_DIR/$1"
if [ "$1" == 'v2ray' ]; then
    cp -f v2ctl "$APP_DIR/$1-$2/"
    rm -f "$APP_DIR/v2ctl"
    ln -s "$APP_DIR/$1-$2/v2ctl" "$APP_DIR/v2ctl"
    cp -f geoip.dat "$APP_DIR/"
    cp -f geosite.dat "$APP_DIR/"
fi

cp -f libev.4.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libcares.2.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.3.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libsodium.23.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libpcre.1.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.2.16.2.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
