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
    
    static func importConfigFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Config File".localized
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.becomeKey()
        openPanel.begin { (result) -> Void in
            if (result.rawValue == NSApplication.ModalResponse.OK.rawValue && (openPanel.url) != nil) {
                let fileManager = FileManager.default
                let filePath: String = (openPanel.url?.path)!
                if fileManager.fileExists(atPath: filePath) && filePath.hasSuffix("json") {
                    notificationDeliver(title: "Importing start", subTitle: "Importing... Hold on please", text: "")
                    DispatchQueue.global().async {
                        let data = fileManager.contents(atPath: filePath)
                        let readString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                        let readStringData = readString.data(using: String.Encoding.utf8.rawValue)
                        
                        let jsonArr1 = try! JSONSerialization.jsonObject(with: readStringData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        let serverGroup = ServerGroup()
                        serverGroup.groupName = "Default Group".localized
                        for item in jsonArr1.object(forKey: "configs") as! [[String: AnyObject]]{
                            let profile = ServerProfile()
                            profile.serverHost = item["server"] as! String
                            profile.serverPort = UInt16((item["server_port"] as! Int))
                            profile.method = item["method"] as! String
                            profile.password = item["password"] as! String
                            profile.remark = item["remarks"] as! String
                            
                            profile.groupId = serverGroup.groupId
                            
                            if (item["obfs"] != nil) {
                                profile.obfs = item["obfs"] as! String
                                profile.xProtocol = item["protocol"] as! String
                                if (item["obfsparam"] != nil){
                                    profile.obfsParam = item["obfsparam"] as! String
                                }
                                if (item["protocolparam"] != nil){
                                    profile.xProtocolParam = item["protocolparam"] as! String
                                }
                            }
                            serverGroup.serverProfiles.append(profile)
                        }
                        ServerGroupManager.serverGroups.append(serverGroup)
                        ServerGroupManager.save()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFY_SERVER_PROFILES_CHANGED), object: nil)
                        let configsCount = (jsonArr1.object(forKey: "configs") as! [[String: AnyObject]]).count
                        notificationDeliver(title: "Import configurations succeed", subTitle: "", text: "Successful import items, total: ", String(configsCount))
                    }
                } else {
                    notificationDeliver(title: "Import configurations failed", subTitle: "Invalid config file", text: "")
                    return
                }
            }
        }
    }
    
    static func exportConfigFile() {
        //读取example文件，删掉configs里面的配置，再用NSDictionary填充到configs里面
        let fileManager = FileManager.default
        
        let filePath: String = Bundle.main.path(forResource: "example-gui-config", ofType: "json")!
        let data = fileManager.contents(atPath: filePath)
        let readString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
        let readStringData = readString.data(using: String.Encoding.utf8.rawValue)
        let jsonArr1 = try! JSONSerialization.jsonObject(with: readStringData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
        
        let configsArray: NSMutableArray = [] //not using var?
        var count = 0
        for g in ServerGroupManager.serverGroups {
            count += g.serverProfiles.count
            for profile in g.serverProfiles {
                let configProfile: NSMutableDictionary = [:] //not using var?
                //standard ss profile
                configProfile.setValue(true, forKey: "enable")
                configProfile.setValue(profile.serverHost, forKey: "server")
                configProfile.setValue(NSNumber(value: profile.serverPort as UInt16), forKey: "server_port")//not work
                configProfile.setValue(profile.password, forKey: "password")
                configProfile.setValue(profile.method, forKey: "method")
                configProfile.setValue(profile.remark, forKey: "remarks")
                configProfile.setValue(profile.remark.data(using: String.Encoding.utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)), forKey: "remarks_base64")
                //ssr
                configProfile.setValue(profile.obfs, forKey: "obfs")
                configProfile.setValue(profile.xProtocol, forKey: "protocol")
                configProfile.setValue(profile.obfsParam, forKey: "obfsparam")
                configProfile.setValue(profile.xProtocolParam, forKey: "protocolparam")
                
                configProfile.setValue(g.groupName, forKey: "group")
                configsArray.add(configProfile)
            }
        }
        
        jsonArr1.setValue(configsArray, forKey: "configs")
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonArr1, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        let savePanel = NSSavePanel()
        savePanel.title = "Export server configurations".localized
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "server-export.json"
        savePanel.becomeKey()
        savePanel.begin { (result) -> Void in
            if (result.rawValue == NSApplication.ModalResponse.OK.rawValue && (savePanel.url) != nil) {
                //write jsonArr1 back to file
                try! jsonString.write(toFile: (savePanel.url?.path)!, atomically: true, encoding: String.Encoding.utf8)
                NSWorkspace.shared.selectFile((savePanel.url?.path)!, inFileViewerRootedAtPath: (savePanel.directoryURL?.path)!)
                notificationDeliver(title: "Export server configurations succeed", subTitle: "", text: "Export items succeed, total: ", String(count))
            }
        }
    }
}
