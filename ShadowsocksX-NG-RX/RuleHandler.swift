//
//  RuleHandler.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2021/4/17.
//  Copyright © 2021 felix.xu. All rights reserved.
//

import Foundation
import Alamofire

func writeRules(url: String? = nil) {
    let geoPath = NSHomeDirectory() + APP_SUPPORT_DIR + "chn_geo.acl"
    let fileMgr = FileManager.default
    var chnContent = ""
    if url == nil {
        if fileMgr.fileExists(atPath: geoPath) {
            chnContent = try! String(contentsOfFile: geoPath, encoding: .utf8)
        } else {
            chnContent = try! String(contentsOfFile: Bundle.main.path(forResource: "chn", ofType: "acl")!, encoding: .utf8)
        }
        toACLFile(chnContent: chnContent)
    } else {
        notificationDeliver(title: "ACL is Updating Title", subTitle: "", text: "")
        AF.request(url!).responseString {
            response in
            switch response.result {
            case .success:
                if let v = response.value {
                    try? fileMgr.removeItem(atPath: geoPath)
                    fileMgr.createFile(atPath: geoPath, contents: v.data(using: .utf8))
                    toACLFile(chnContent: v)
                    ReloadConfSSLocal()
                    notificationDeliver(title: "ACL Update Succeed Title", subTitle: "", text: "")
                }
            case .failure:
                notificationDeliver(title: "ACL Update Failed Title", subTitle: "", text: "")
            }
        }
    }
}

func toACLFile(chnContent: String) {
    let rules = UserDefaults.standard.stringArray(forKey: UserKeys.BypassRules) ?? []
    var data: String = ["[proxy_all]", "", "[bypass_list]", ""].joined(separator: "\n")
    data.append(chnContent)
    data.append("\n")
    data.append(rules.joined(separator: "\n"))
    let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "chn.acl"
    try? data.data(using: .utf8)?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
}
