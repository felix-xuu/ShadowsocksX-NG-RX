#!/bin/sh

#  install.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`

mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2"
cp -f haproxy "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1-$2/$1" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/$1"
