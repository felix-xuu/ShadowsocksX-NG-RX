//
//  ServerGroup.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/13.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class ServerGroup: NSObject {
    var groupId: String
    var isSubscription: Bool = false
    var serverProfiles: [ServerProfile] = []
    
    @objc dynamic var subscribeUrl: String = ""
    @objc dynamic var maxCount: Int = -1 // -1 is not limited
    @objc dynamic var groupName: String = ""
    @objc dynamic var token: String = ""
    @objc dynamic var autoUpdate: Bool = true
    
    override init() {
        groupId = UUID().uuidString
    }
    
    static func fromDictionaries(_ data: [[String:AnyObject]]) -> [ServerGroup] {
        var groups = [ServerGroup]()
        for item in data {
            groups.append(fromDictionary(item))
        }
        return groups
    }
    
    static func fromDictionary(_ data: [String:AnyObject]) -> ServerGroup {
        let group = ServerGroup()
        group.groupId = data["id"] as! String
        group.groupName = data["groupName"] as! String
        group.isSubscription = data["isSubscription"] as! Bool
        group.serverProfiles = ServerProfile.fromDictionaries(data["profiles"] as! [[String : AnyObject]]) as [ServerProfile]
        group.subscribeUrl = data["subscribeUrl"] as! String
        group.maxCount = data["maxCount"] as! Int
        group.token = data["token"] as! String
        group.autoUpdate = data["autoUpdate"] as! Bool
        return group
    }
    
    static func toDictionaries(_ data: [ServerGroup]) -> [[String:AnyObject]] {
        var rets = [[String:AnyObject]]()
        for item in data {
            rets.append(toDictionary(item))
        }
        return rets
    }
    
    static func toDictionary(_ data: ServerGroup) -> [String:AnyObject] {
        var ret = [String : AnyObject]()
        ret["id"] = data.groupId as AnyObject
        ret["groupName"] = data.groupName as AnyObject
        ret["isSubscription"] = data.isSubscription as AnyObject
        ret["profiles"] = ServerProfile.toDictionaries(data.serverProfiles) as AnyObject
        ret["subscribeUrl"] = data.subscribeUrl as AnyObject
        ret["maxCount"] = data.maxCount as AnyObject
        ret["token"] = data.token as AnyObject
        ret["autoUpdate"] = data.autoUpdate as AnyObject
        return ret
    }
}
