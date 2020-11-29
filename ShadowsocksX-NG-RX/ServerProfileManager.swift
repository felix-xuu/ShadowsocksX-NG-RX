//
//  ServerProfileManager.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6. Modified by 秦宇航 17/7/22 
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ServerProfileManager: NSObject {
    
    static let instance: ServerProfileManager = ServerProfileManager()
    static var activeProfile: ServerProfile?
    
    fileprivate override init() {
        let defaults = UserDefaults.standard

        if let profile = defaults.object(forKey: UserKeys.ActiveServerProfile) {
            ServerProfileManager.activeProfile = ServerProfile.fromDictionary(profile as! [String : AnyObject])
        }
        NSLog("Server manager init")
    }
    
    static func setActiveProfile(_ profile: ServerProfile?) {
        activeProfile = profile
        if profile == nil {
            UserDefaults.standard.removeObject(forKey: UserKeys.ActiveServerProfile)
        } else {
            UserDefaults.standard.set(ServerProfile.toDictionary(profile!), forKey: UserKeys.ActiveServerProfile)
        }
    }
    
    static func getActiveProfileId() -> String {
        if let _ = activeProfile {
            return activeProfile!.uuid
        }
        return ""
    }
}
