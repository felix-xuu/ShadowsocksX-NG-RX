//
//  LoadBalance.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2019/8/18.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class LoadBalance: NSObject {
    static let strategies: [(String, String)] = [("roundrobin", "In turns".localized), ("random", "Random".localized), ("leastconn", "Least conns priority".localized), ("first", "First available".localized)]
    
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
        writeHaproxyConfFile()
        let accumulate = getLoadBalanceGroup()?.serverProfiles.reduce(into: [:], {$0[$1.method, default: 0] += 1})
        let method = accumulate?.max(by: {$0.1 < $1.1})?.key
        let profile = getLoadBalanceGroup()?.serverProfiles.first(where: {$0.method == method})
        profile?.serverHost = UserDefaults.standard.string(forKey: UserKeys.ListenAddress)!
        profile?.serverPort = uint16(UserDefaults.standard.integer(forKey: UserKeys.LoadbalancePort))
        writeSSLocalConfFile(profile!.toJsonConfig())
        ReloadConfSSLocal()
        (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
        ReloadConfHaproxy()
    }
}
