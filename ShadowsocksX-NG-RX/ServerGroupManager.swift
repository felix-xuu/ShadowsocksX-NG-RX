//
//  ServerGroupManager.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/13.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class ServerGroupManager: NSObject {
    static let instance: ServerGroupManager = ServerGroupManager()
    static var serverGroups = [ServerGroup]()
    
    override init() {
        let defaults = UserDefaults.standard
        if let groups = defaults.array(forKey: UserKeys.ServerGroups) {
            for item in groups {
                ServerGroupManager.serverGroups.append(ServerGroup.fromDictionary(item as! [String : AnyObject]))
            }
        }
        NSLog("ServerGroup manager init")
    }
    
    static func save() {
        UserDefaults.standard.set(ServerGroup.toDictionaries(serverGroups), forKey: UserKeys.ServerGroups)
    }
    
    static func getServerGroupByGroupId(_ groupId: String) -> ServerGroup? {
        return serverGroups.first(where: {$0.groupId == groupId})
    }
    
    static func getSubscriptions() -> [ServerGroup] {
        return serverGroups.filter({$0.isSubscription})
    }
}
