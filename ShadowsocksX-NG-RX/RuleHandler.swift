//
//  RuleHandler.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2021/4/17.
//  Copyright © 2021 felix.xu. All rights reserved.
//

import Foundation

func writeRules(rules:[String]) {
    let bundle = Bundle.main
    let chnPath = bundle.path(forResource: "chn", ofType: "acl")
    var chnContent = try! String(contentsOfFile: chnPath!, encoding: .utf8)
    chnContent.append(rules.joined(separator: "\n"))
    var data: Data = Data.init()
    data = chnContent.data(using: .utf8) ?? Data.init()
    let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "chn.acl"
    try? data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
}
