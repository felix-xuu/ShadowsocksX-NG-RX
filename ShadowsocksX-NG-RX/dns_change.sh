#!/bin/sh

#  dnsChange.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix Xu on 2020/7/12.
#  Copyright © 2020 felix.xu. All rights reserved.

networksetup -setdnsservers Wi-Fi $1
