//
//  ServerProfile.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ServerProfile: NSObject {
    var uuid: String
    
    @objc dynamic var serverHost: String = ""
    @objc dynamic var serverPort: uint16 = 8379
    @objc dynamic var method: String = "none"
    @objc dynamic var password: String = ""
    @objc dynamic var remark: String = ""
    
    @objc dynamic var xProtocol: String = "origin"
    @objc dynamic var xProtocolParam: String = ""
    @objc dynamic var obfs: String = "plain"
    @objc dynamic var obfsParam: String = ""
    
    @objc dynamic var url: String = ""
    @objc dynamic var group: String = ""
    var groupId: String = ""
    var hashVal: String = ""
    var latency: String?
    
    override init() {
        uuid = UUID().uuidString
    }
    
    static func fromDictionaries(_ data:[[String:AnyObject]]) -> [ServerProfile] {
        var d = [ServerProfile]()
        for item in data {
            d.append(fromDictionary(item))
        }
        return d
    }
    
    static func fromDictionary(_ data:[String:AnyObject]) -> ServerProfile {
        let profile = ServerProfile()
        profile.serverHost = data["ServerHost"] as! String
        profile.serverPort = (data["ServerPort"] as! NSNumber).uint16Value
        profile.method = data["Method"] as? String ?? ""
        profile.password = data["Password"] as? String ?? ""
        
        profile.remark = data["remarks"] as? String ?? ""
        profile.obfs = data["obfs"] as? String ?? ""
        profile.obfsParam = data["obfsparam"] as? String ?? ""
        profile.xProtocol = data["xProtocol"] as? String ?? ""
        profile.xProtocolParam = data["protoparam"] as? String ?? ""
        profile.url = data["url"] as? String ?? ""
        profile.groupId = data["groupId"] as? String ?? ""
        profile.group = data["group"] as? String ?? ""
        profile.hashVal = data["hashVal"] as? String ?? ""
        return profile
    }
    
    static func toDictionary(_ data: ServerProfile) -> [String:AnyObject] {
        var d = [String:AnyObject]()
        d["Id"] = data.uuid as AnyObject?
        d["ServerHost"] = data.serverHost as AnyObject?
        d["ServerPort"] = NSNumber(value: data.serverPort as UInt16)
        d["Method"] = data.method as AnyObject?
        d["Password"] = data.password as AnyObject?
        d["remarks"] = data.remark as AnyObject?
        d["xProtocol"] = data.xProtocol as AnyObject?
        d["protoparam"] = data.xProtocolParam as AnyObject?
        d["obfs"] = data.obfs as AnyObject?
        d["obfsparam"] = data.obfsParam as AnyObject?
        d["url"] = data.url as AnyObject?
        d["groupId"] = data.groupId as AnyObject?
        d["group"] = data.group as AnyObject?
        d["hashVal"] = data.hashVal as AnyObject?
        return d
    }
    
    static func toDictionaries(_ data:[ServerProfile]) -> [[String:AnyObject]] {
        var d = [[String:AnyObject]]()
        for item in data {
            d.append(toDictionary(item))
        }
        return d
    }
    
    func toJsonConfig() -> [String: AnyObject] {
        // supply json file for ss-local only export vital param
        var conf: [String: AnyObject] = ["server": serverHost as AnyObject,
                                         "server_port": NSNumber(value: serverPort as UInt16),
                                         "password": password as AnyObject,
                                         "method": method as AnyObject,]
        
        let defaults = UserDefaults.standard
        conf["local_port"] = NSNumber(value: UInt16(defaults.integer(forKey: UserKeys.Socks5_ListenPort)) as UInt16)
        conf["local_address"] = defaults.string(forKey: UserKeys.ListenAddress) as AnyObject?
        conf["timeout"] = NSNumber(value: UInt32(defaults.integer(forKey: UserKeys.Socks5_Timeout)) as UInt32)
        
        conf["protocol"] = xProtocol as AnyObject?
        conf["protocol_param"] = xProtocolParam as AnyObject?
        conf["obfs"] = obfs as AnyObject?
        conf["obfs_param"] = obfsParam as AnyObject?
        
        return conf
    }
    
    func getValidId() -> String {
        return ServerGroupManager.serverGroups.first(where: {$0.groupId == groupId})!.isSubscription ?  self.hashVal : self.uuid
    }
    
    func isValid() -> Bool {
        func validateIpAddress(_ ipToValidate: String) -> Bool {
            var sin = sockaddr_in()
            var sin6 = sockaddr_in6()
            
            if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
                // IPv6 peer.
                return true
            } else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
                // IPv4 peer.
                return true
            }
            return false;
        }
        
        func validateDomainName(_ value: String) -> Bool {
            let validHostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
            if (value.range(of: validHostnameRegex, options: .regularExpression) != nil) {
                return true
            }
            return false
        }
        
        if !(validateIpAddress(serverHost) || validateDomainName(serverHost)){
            return false
        }
        
        if password.isEmpty {
            return false
        }
        
        if (xProtocol.isEmpty && !obfs.isEmpty)||(!xProtocol.isEmpty && obfs.isEmpty){
            return false
        }
        return true
    }
    
    func URL() -> String {
        if !url.isEmpty {
            return url
        }
        if(obfs == "plain") {
            let parts = "\(method):\(password)@\(serverHost):\(serverPort)"
            let base64String = parts.data(using: String.Encoding.utf8)?
                .base64EncodedString(options: NSData.Base64EncodingOptions())
            if var s = base64String {
                s = s.trimmingCharacters(in: CharacterSet(charactersIn: "="))
                return "ss://\(s)"
            }
        } else {
            let firstParts = "\(serverHost):\(serverPort):\(xProtocol):\(method):\(obfs):"
            let secondParts = "\(password)"
            // ssr:// + base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
            let base64PasswordString = encode64(str: secondParts)
            let base64obfsParamString = encode64(str: obfsParam)
            let base64xProtocolParamString = encode64(str: xProtocolParam)
            let base64RemarkString = encode64(str: remark)
            let base64GroupString = encode64(str: group)
            
            var s = firstParts + base64PasswordString + "/?" + "obfsparam=" + base64obfsParamString + "&protoparam=" + base64xProtocolParamString + "&remarks=" + base64RemarkString + "&group=" + base64GroupString
            s = encode64(str: s)
            return "ssr://\(s)"
        }
        return ""
    }
    
    func title() -> String {
        var title: String
        if remark.isEmpty {
            title = "\(serverHost):\(serverPort)"
        } else {
            title = "\(remark) (\(serverHost):\(serverPort))"
        }
        if let t = latency {
            return t == "timeout" ? title + " - \(t)" : title + " - \(t)ms"
        }
        return title
    }
    
    func titleForActive() -> String {
        var title: String
        if remark.isEmpty {
            title = "\(serverHost):\(serverPort)"
        } else {
            title = "\(remark)"
        }
        if let t = latency {
            return t == "timeout" ? title + " - \(t)" : title + " - \(t)ms"
        }
        return title
    }
}
