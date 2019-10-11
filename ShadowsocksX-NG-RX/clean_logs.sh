#!/bin/sh

#  clean_logs.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix Xu on 2019/8/18.
#  Copyright © 2019 felix.xu. All rights reserved.

cd `dirname "${BASH_SOURCE[0]}"`
rm "$HOME/Library/Logs/ssr-haproxy.log"
rm "$HOME/Library/Logs/ssr-local.log"
rm "$HOME/Library/Logs/ssr-privoxy.log"
rm "$HOME/Library/Logs/ssr-v2ray.log"
