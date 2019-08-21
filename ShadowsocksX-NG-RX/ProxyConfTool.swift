//
//  ProxyConfTool.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/15.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation
import SystemConfiguration

class ProxyConfTool: NSObject {
    static func networkServicesList() -> [NSDictionary] {
        var result = [NSDictionary]()
        let scp = SCPreferencesCreate(nil, "ShadowsocksX" as CFString, nil)
        let sets = SCPreferencesGetValue(scp!, kSCPrefNetworkServices)
        for item in sets!.allKeys {
            let service = sets!.value(forKey: item) as! NSMutableDictionary
            let userDefinedName = service.value(forKey: kSCPropUserDefinedName as String)
            result.append(NSDictionary(dictionaryLiteral: ("key", item), ("userDefinedName", userDefinedName as! String)))
        }
        return result
    }
}
