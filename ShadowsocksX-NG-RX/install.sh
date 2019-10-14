#!/bin/sh

#  install.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`

mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2"
cp -f $1 "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/$1" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1"
if [ "$1" == 'v2ray' ]; then
    cp -f v2ctl "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/"
    rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/v2ctl"
    ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/v2ctl" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/v2ctl"
    cp -f geoip.dat "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
    cp -f geosite.dat "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
fi
