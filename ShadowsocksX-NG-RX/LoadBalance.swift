//
//  LoadBalance.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2019/8/18.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class LoadBalance: NSObject {
    static let strategies: [(String, String)] = [("roundrobin", "In turns"), ("random", "Random"), ("leastconn", "Least conns priority"), ("first", "First available")]
    
    static func getLoadBalanceGroup() -> ServerGroup? {
        if let group = UserDefaults.standard.object(forKey: UserKeys.LoadbalanceGroup) {
            return ServerGroup.fromDictionary(group as! [String : AnyObject])
        }
        return nil
    }
    
    static func getLoadBalanceProfiles() -> [ServerProfile] {
        if let profiles = UserDefaults.standard.array(forKey: UserKeys.LoadbalanceProfiles) {
            return ServerProfile.fromDictionaries(profiles as! [[String : AnyObject]])
        }
        return []
    }
    
    static func enableLoadBalance() {
        if getLoadBalanceProfiles().count == 0 {
            return
        }
        writeHaproxyConfFile(type: UserKeys.Mode_Loadbalance)
        let accumulate = getLoadBalanceGroup()?.serverProfiles.reduce(into: [:], {$0[$1.method, default: 0] += 1})
        let method = accumulate?.max(by: {$0.1 < $1.1})?.key
        let profile = getLoadBalanceGroup()?.serverProfiles.first(where: {$0.method == method})
        var config = profile!.toJsonConfig()
        config["server"] = "127.0.0.1" as AnyObject
        config["server_port"] = uint16(UserDefaults.standard.integer(forKey: UserKeys.LoadbalancePort)) as AnyObject
        writeSSLocalConfFile(config)
        ReloadConfSSLocal()
        ReloadConfHaproxy()
    }
    
    static func cleanLoadBalanceAfterUpdateFeed() {
        var group = getLoadBalanceGroup()
        var balanceProfiles = getLoadBalanceProfiles()
        if group == nil {
            return
        }
        for item in ServerGroupManager.getSubscriptions() {
            if item.groupId == group!.groupId {
                group = item
                UserDefaults.standard.set(ServerGroup.toDictionary(group!), forKey: UserKeys.LoadbalanceGroup)
            }
        }
        for item in balanceProfiles {
            if group!.serverProfiles.filter({$0.hashVal == item.hashVal}).isEmpty {
                balanceProfiles.removeAll(where: {$0.hashVal == item.hashVal})
            }
        }
        UserDefaults.standard.set(ServerProfile.toDictionaries(balanceProfiles), forKey: UserKeys.LoadbalanceProfiles)
        if UserDefaults.standard.string(forKey: UserKeys.ShadowsocksXRunningMode) == UserKeys.Mode_Loadbalance {
            writeHaproxyConfFile(type: UserKeys.Mode_Loadbalance)
            ReloadConfHaproxy()
        }
    }
}
