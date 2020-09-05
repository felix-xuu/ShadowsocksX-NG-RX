//
//  PACUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/9.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import Alamofire

let PACRulesDirPath = NSHomeDirectory() + "/.ShadowsocksX-NG-RX/"
let PACUserRuleFilePath = PACRulesDirPath + "user-rule.txt"
let PACFilePath = PACRulesDirPath + "gfwlist.js"
let GFWListFilePath = PACRulesDirPath + "gfwlist.txt"

let ACLWhiteListFilePath = PACRulesDirPath + "chn.acl"
let ACLGFWListFilePath = PACRulesDirPath + "gfwlist.acl"

// Because of LocalSocks5.ListenPort may be changed
func SyncPac() {
    var needGenerate = false
    
    let nowSocks5Port = UserDefaults.standard.integer(forKey: UserKeys.Socks5_ListenPort)
    let oldSocks5Port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort.Old")
    if nowSocks5Port != oldSocks5Port {
        needGenerate = true
        UserDefaults.standard.set(nowSocks5Port, forKey: "LocalSocks5.ListenPort.Old")
    }
    
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: PACRulesDirPath) {
        needGenerate = true
    }
    
    if !fileMgr.fileExists(atPath: PACUserRuleFilePath) || !fileMgr.fileExists(atPath: GFWListFilePath) || !fileMgr.fileExists(atPath: ACLWhiteListFilePath) || !fileMgr.fileExists(atPath: ACLGFWListFilePath) || !fileMgr.fileExists(atPath: PACFilePath) {
        needGenerate = true
    }
    
    if needGenerate {
        initRuleFile()
        if !GeneratePACFile() {
            NSLog("Generate PAC filed")
        }
    }
}

func initRuleFile() {
    let fileMgr = FileManager.default
    // Maker the dir if rulesDirPath is not exesited.
    if !fileMgr.fileExists(atPath: PACRulesDirPath) {
        try? fileMgr.createDirectory(atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    var src = Bundle.main.path(forResource: "gfwlist", ofType: "txt")
    try? fileMgr.removeItem(atPath: GFWListFilePath)
    try? fileMgr.copyItem(atPath: src!, toPath: GFWListFilePath)
    
    // If user-rule.txt is not exsited, copy from bundle
    if !fileMgr.fileExists(atPath: PACUserRuleFilePath) {
        let src = Bundle.main.path(forResource: "user-rule", ofType: "txt")
        try? fileMgr.copyItem(atPath: src!, toPath: PACUserRuleFilePath)
    }
    
    src = Bundle.main.path(forResource: "chn", ofType: "acl")
    try? fileMgr.removeItem(atPath: ACLWhiteListFilePath)
    try? fileMgr.copyItem(atPath: src!, toPath: ACLWhiteListFilePath)

    src = Bundle.main.path(forResource: "gfwlist", ofType: "acl")
    try? fileMgr.removeItem(atPath: ACLGFWListFilePath)
    try? fileMgr.copyItem(atPath: src!, toPath: ACLGFWListFilePath)
}

func GeneratePACFile() -> Bool {
    let socks5Port = UserDefaults.standard.integer(forKey: UserKeys.Socks5_ListenPort)
    
    do {
        let gfwlist = try String(contentsOfFile: GFWListFilePath, encoding: String.Encoding.utf8)
        if let data = Data(base64Encoded: gfwlist, options: .ignoreUnknownCharacters) {
            let str = String(data: data, encoding: String.Encoding.utf8)
            var lines = str!.components(separatedBy: CharacterSet.newlines)
            
            do {
                let userRuleStr = try String(contentsOfFile: PACUserRuleFilePath, encoding: String.Encoding.utf8)
                let userRuleLines = userRuleStr.components(separatedBy: CharacterSet.newlines)
                
                lines = userRuleLines + lines
            } catch {
                NSLog("Not found user-rule.txt")
            }
            
            // Filter empty and comment lines
            lines = lines.filter({ (s: String) -> Bool in
                if s.isEmpty {
                    return false
                }
                let c = s[s.startIndex]
                if c == "!" || c == "[" {
                    return false
                }
                return true
            })
            
            do {
                // rule lines to json array
                let rulesJsonData: Data = try JSONSerialization.data(withJSONObject: lines, options: .prettyPrinted)
                let rulesJsonStr = String(data: rulesJsonData, encoding: String.Encoding.utf8)
                
                // Get raw pac js
                let jsPath = Bundle.main.url(forResource: "abp", withExtension: "js")
                let jsData = try? Data(contentsOf: jsPath!)
                var jsStr = String(data: jsData!, encoding: String.Encoding.utf8)
                
                // Replace rules placeholder in pac js
                jsStr = jsStr!.replacingOccurrences(of: "__RULES__"
                    , with: rulesJsonStr!)
                // Replace __SOCKS5PORT__ palcholder in pac js
                let result = jsStr!.replacingOccurrences(of: "__SOCKS5PORT__"
                    , with: "\(socks5Port)")
                
                // Write the pac js to file.
                try result.data(using: String.Encoding.utf8)?.write(to: URL(fileURLWithPath: PACFilePath), options: .atomic)
                return true
            } catch {
                NSLog("Generate user's rule failed")
            }
        }
    } catch {
        NSLog("Not found gfwlist.txt")
    }
    return false
}

//func ACLFromUserRule(userRuleLines:[String]){
//    do {
//        var AutoACL = try String(contentsOfFile: ACLGFWListFilePath, encoding: String.Encoding.utf8)
//        var WhiteACL = try String(contentsOfFile: ACLWhiteListFilePath, encoding: String.Encoding.utf8)
//        let rule = userRuleLines.filter({ (s: String) -> Bool in
//            if s.isEmpty {
//                return false
//            }
//            let c = s[s.startIndex]
//            if c == "!" || c == "[" {
//                return false
//            }
//            return true
//        })
//        rule.forEach({ (s: String) -> Void in
//            // add the @@ to whitelist and other to GFWList
//            if (s.hasPrefix("@@")){
//                let str = s.replacingOccurrences(of: "@@", with: "").components(separatedBy: ".").joined(separator:"\\.").replacingOccurrences(of: "*\\.", with: "^(.*\\.)?")
//                if (!WhiteACL.contains(str)){
//                    WhiteACL += (str + "$\n")
//
//                }
//            }
//            if (s.hasPrefix("||")){
//                let str = s.replacingOccurrences(of: "||", with: "").components(separatedBy: ".").joined(separator:"\\.").replacingOccurrences(of: "*\\.", with: "^(.*\\.)?")
//                if (!AutoACL.contains(str)){
//                    AutoACL += (str + "$\n")
//                }
//            }
//        })
//        // write file back to ACL
//        try WhiteACL.data(using: String.Encoding.utf8)?.write(to: URL(fileURLWithPath: ACLWhiteListFilePath), options: .atomic)
//        try AutoACL.data(using: String.Encoding.utf8)?.write(to: URL(fileURLWithPath: ACLGFWListFilePath), options: .atomic)
//    } catch {
//        NSLog("Write user rule to ACL file failed")
//    }
//}

func UpdatePACFromGFWList() {
    // Make the dir if rulesDirPath is not exesited.
    if !FileManager.default.fileExists(atPath: PACRulesDirPath) {
        do {
            try FileManager.default.createDirectory(atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Create directory failed")
        }
    }
    
    let url = UserDefaults.standard.string(forKey: UserKeys.GFWListURL)
    AF.request(url!)
        .responseString {
            response in
            switch response.result {
            case .success:
                if let v = response.value {
                    do {
                        try v.write(toFile: GFWListFilePath, atomically: true, encoding: String.Encoding.utf8)
                        if GeneratePACFile() {
                            notificationDeliver(title: "PAC has been updated to latest GFW List", subTitle: "", text: "")
                        }
                    } catch {
                        NSLog("Write PAC file failed")
                    }
                }
            case .failure:
                notificationDeliver(title: "Failed to download latest GFW List", subTitle: "", text: "")
            }
    }
}

func UpdateACL(){
    if !FileManager.default.fileExists(atPath: PACRulesDirPath) {
        do {
            try FileManager.default.createDirectory(atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Create directory failed")
        }
    }
    
    let whiteUrl = UserDefaults.standard.string(forKey: UserKeys.ACLWhiteListURL)
    AF.request(whiteUrl!).responseString {
        response in
        switch response.result {
        case .success:
            if let v = response.value {
                do {
                    try v.write(toFile: ACLWhiteListFilePath, atomically: true, encoding: String.Encoding.utf8)
                    notificationDeliver(title: "ACL White List updated successful", subTitle: "", text: "")
                } catch {
                    NSLog("Write ACL White List file failed")
                }
            }
        case .failure:
            notificationDeliver(title: "Failed to download latest ACL White List", subTitle: "", text: "")
        }
    }
    
    let autoUrl = UserDefaults.standard.string(forKey: UserKeys.ACLAutoListURL)
    AF.request(autoUrl!).responseString {
        response in
        switch response.result {
        case .success:
            if let v = response.value {
                do {
                    try v.write(toFile: ACLGFWListFilePath, atomically: true, encoding: String.Encoding.utf8)
                    notificationDeliver(title: "ACL Auto List update successful", subTitle: "", text: "")
                } catch {
                    NSLog("Write ACL Auto file failed")
                }
            }
        case .failure:
            notificationDeliver(title: "Failed to download latest ACL Auto List", subTitle: "", text: "")
        }
    }
}
