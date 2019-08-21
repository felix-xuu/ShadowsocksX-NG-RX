#!/bin/sh

#  install_privoxy.sh
#  ShadowsocksX-NG
#
#  Created by 王晨 on 16/10/7.
#  Copyright © 2016年 zhfish. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`
privoxyVersion=3.0.28
mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/privoxy-$privoxyVersion"
cp -f privoxy "$HOME/Library/Application Support/ShadowsocksX-NG-RX/privoxy-$privoxyVersion/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/privoxy"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/privoxy-$privoxyVersion/privoxy" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/privoxy"
