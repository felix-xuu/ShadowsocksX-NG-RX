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
