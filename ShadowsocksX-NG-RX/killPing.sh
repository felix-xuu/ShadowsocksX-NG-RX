#!/bin/sh

#  killPing.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix Xu on 2020/5/2.
#  Copyright © 2020 felix.xu. All rights reserved.

ps -ef|grep ss-local|grep -v grep|awk '{print $2}'|xargs kill
