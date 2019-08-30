//
//  SubscribeManager.swift
//  ShadowsocksX-NG
//
//  Created by 秦宇航 on 2017/6/19.
//  Copyright © 2017年 qiuyuzhou. All rights reserved.
//

import Foundation
import Alamofire

class SubscribeManager:NSObject{
    static var subscribesDefault = [[String: AnyObject]]()
    static var queryCount = -1
    static var autoUpdateCount = -1
    
    static func updateAllServerFromSubscribe() {
        queryCount = 0
        let subscribes = ServerGroupManager.getSubscriptions()
        DispatchQueue.global().async {
            subscribes.forEach{ value in
                SubscribeManager.updateServerFromSubscription(value)
            }
            while queryCount != subscribes.count {
                usleep(100000)
            }
            DispatchQueue.main.async {
                ServerGroupManager.save()
                LoadBalance.cleanLoadBalanceAfterUpdateFeed()
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
                queryCount = -1
            }
        }
    }
    
    static func updateServerFromSubscription(_ data: ServerGroup) {
        func updateServerHandler(resString: String) {
            let decodeRes = decode64(resString)!
            let urls = splitor(url: decodeRes)
            let maxN = (data.maxCount > urls.count) ? urls.count : (data.maxCount == -1) ? urls.count: data.maxCount
            for index in 0..<maxN {
                if let profileDict = ParseAppURLSchemes(URL(string: urls[index])) {
                    let profile = ServerProfile.fromDictionary(profileDict as [String : AnyObject])
                    profile.url = urls[index]
                    profile.hashVal = profile.md5()
                    profile.groupId = data.groupId
                    data.serverProfiles.append(profile)
                }
            }
            notificationDeliver(title: "Subscription Update Succeed Title", subTitle: "", text: "Subscription Update Succeed Info", data.subscribeUrl)
        }
        
        sendRequest(data: data, callback: { resString in
            if resString.isEmpty { return }
            updateServerHandler(resString: resString)
        })
    }
    
    static func sendRequest(data: ServerGroup, callback: @escaping (String) -> Void) {
        let headers: HTTPHeaders = [
            //            "Authorization": "Basic U2hhZG93c29ja1gtTkctUg==",
            //            "Accept": "application/json",
            "token": data.token,
            //            "User-Agent": "ShadowsocksX-NG-RX" + (getLocalInfo()["CFBundleShortVersionString"] as! String) + " Version " + (getLocalInfo()["CFBundleVersion"] as! String)
        ]
        
        Alamofire.request(data.subscribeUrl, headers: headers).responseString {
            response in
            if response.result.isSuccess {
                data.serverProfiles = []
                callback(response.result.value!)
            } else {
                notificationDeliver(title: "Subscription Update Failed Title", subTitle: "", text: "Subscription Update Failed Info", data.subscribeUrl)
            }
            if SubscribeManager.queryCount != -1 {
                SubscribeManager.queryCount += 1
            }
            if SubscribeManager.autoUpdateCount != -1 {
                SubscribeManager.autoUpdateCount += 1
            }
        }
    }
}
