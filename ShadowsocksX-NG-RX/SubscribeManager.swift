//
//  SubscribeManager.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/13.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation
import Alamofire

class SubscribeManager:NSObject{
    static var subscribesDefault = [[String: AnyObject]]()
    static var queryCount = 0
    
    static func updateAllServerFromSubscribe() {
        let subscribes = ServerGroupManager.getSubscriptions()
        DispatchQueue.global().async {
            subscribes.forEach{ value in
                SubscribeManager.updateServerFromSubscription(value)
            }
            while queryCount < subscribes.count {
                usleep(100000)
            }
            DispatchQueue.main.async {
                ServerGroupManager.serverGroups.removeAll(where: {$0.isSubscription})
                ServerGroupManager.serverGroups.append(contentsOf: subscribes)
                ServerGroupManager.save()
                LoadBalance.cleanLoadBalanceAfterUpdateFeed()
                if let profile = ServerProfileManager.activeProfile {
                    if ServerGroupManager.getServerGroupByGroupId(profile.groupId)?.serverProfiles.first(where: {$0.getValidId() == profile.getValidId()}) == nil {
                        ServerProfileManager.setActiveProfile(nil)
                    }
                }
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
            }
        }
    }
    
    static func updateServerFromSubscription(_ data: ServerGroup) {
        func updateServerHandler(resString: String) {
            let decodeRes = decode64(str: resString)
            let urls = splitor(url: decodeRes)
            if urls.count == 0 {
                notificationDeliver(title: "Subscription Update Failed Title", subTitle: "", text: "Empty subscriptions", data.subscribeUrl)
                return
            }
            let maxN = (data.maxCount > urls.count) ? urls.count : (data.maxCount == -1) ? urls.count: data.maxCount
            for index in 0..<maxN {
                if let profileDict = ParseAppURLSchemes(url: URL(string: urls[index])!) {
                    let profile = ServerProfile.fromDictionary(profileDict as [String : AnyObject])
                    profile.url = urls[index]
                    profile.hashVal = profile.md5()
                    profile.groupId = data.groupId
                    data.serverProfiles.append(profile)
                }
            }
            queryCount += 1
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
        
        AF.request(data.subscribeUrl, headers: headers).responseString {
            response in
            switch response.result {
            case .success:
                data.serverProfiles = []
                callback(response.value!)
            case .failure:
                queryCount += 1
                notificationDeliver(title: "Subscription Update Failed Title", subTitle: "", text: "Subscription Update Failed Info", data.subscribeUrl)
            }
        }
    }
}
