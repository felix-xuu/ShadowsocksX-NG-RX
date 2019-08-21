//
//  Notifications.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/7.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

let NOTIFY_SERVER_PROFILES_CHANGED = "NOTIFY_SERVER_PROFILES_CHANGED"
let NOTIFY_ADV_PROXY_CONF_CHANGED = "NOTIFY_ADV_PROXY_CONF_CHANGED"
let NOTIFY_ADV_CONF_CHANGED = "NOTIFY_ADV_CONF_CHANGED"
let NOTIFY_INVALIDE_QR = "NOTIFY_INVALIDE_QR"
let NOTIFY_FOUND_SS_URL = "NOTIFY_FOUND_SS_URL"

func notificationDeliver(title: String!, subTitle: String!, text: String...) {
    let notification = NSUserNotification()
    notification.title = title.localized
    if !subTitle.isEmpty {
        notification.subtitle = subTitle.localized
    }
    if !text.isEmpty {
        let t = text[0].localized
        if t.filter({ $0 == "$" }).count != text.count - 1 {
            notification.informativeText = t
        } else {
            var array = t.map({String($0)})
            var i = 1
            for (index, item) in array.enumerated() {
                if item == "$" {
                    array[index] = text[i]
                    i += 1
                }
            }
            notification.informativeText = array.joined(separator: "")
        }
    }
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
}
