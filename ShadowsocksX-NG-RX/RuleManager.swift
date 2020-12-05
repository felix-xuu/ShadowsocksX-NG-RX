//
//  Rule.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/11/28.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Foundation

class RuleManager: NSObject {
    static func getRuleConfigs() -> [RuleConfig] {
        if let configs = UserDefaults.standard.object(forKey: UserKeys.RuleConfigs) {
            return RuleConfig.fromDictionaries(configs as! [[String : AnyObject]])
        }
        return []
    }
    
    static func enableRuleFlow() {
        if let profile = ServerProfileManager.activeProfile {
            writeHaproxyConfFile(type: UserKeys.Mode_Rule)
            var config = profile.toJsonConfig()
            config["server"] = "127.0.0.1" as AnyObject
            config["server_port"] = uint16(UserDefaults.standard.integer(forKey: UserKeys.LoadbalancePort)) as AnyObject
            writeSSLocalConfFile(config)
            generateSSLocalLauchAgentPlist()
            ReloadConfSSLocal()
            ReloadConfHaproxy()
        }
    }
}

class RuleConfig: NSObject {
    var name: String!
    @objc dynamic var rules: String!
    var profile: ServerProfile!
    var enable: Bool = true
    
    static func fromDictionaries(_ data: [[String:AnyObject]]) -> [RuleConfig] {
        var groups = [RuleConfig]()
        for item in data {
            groups.append(fromDictionary(item))
        }
        return groups
    }
    
    static func fromDictionary(_ data: [String:AnyObject]) -> RuleConfig {
        let ruleConf = RuleConfig()
        ruleConf.name = data["name"] as? String
        ruleConf.rules = data["rules"] as? String
        if let profile = data["profile"] {
            ruleConf.profile = ServerProfile.fromDictionary(profile as! [String : AnyObject])
        }
        ruleConf.enable = data["enable"] as! Bool
        return ruleConf
    }
    
    static func toDictionaries(_ data: [RuleConfig]) -> [[String:AnyObject]] {
        var rets = [[String:AnyObject]]()
        for item in data {
            rets.append(toDictionary(item))
        }
        return rets
    }
    
    static func toDictionary(_ data: RuleConfig) -> [String:AnyObject] {
        var ret = [String : AnyObject]()
        ret["name"] = data.name as AnyObject
        ret["rules"] = data.rules as AnyObject
        if let profile = data.profile {
            ret["profile"] = ServerProfile.toDictionary(profile) as AnyObject
        }
        ret["enable"] = data.enable as AnyObject
        return ret
    }
}
