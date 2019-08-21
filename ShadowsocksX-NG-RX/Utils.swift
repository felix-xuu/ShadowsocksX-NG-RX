//
//  Utils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/7.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation


extension String {
    var localized: String {
        let language = UserDefaults.standard.string(forKey: UserKeys.Language)
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        let bundle = Bundle(path: path!)
        let string = bundle?.localizedString(forKey: self, value: nil, table: nil)
        return string!
    }
}

extension Data {
    func sha1() -> String {
        let data = self
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    }
}

extension ServerProfile {
    func md5() -> String {
        let string = "\(self.serverHost)\(self.serverPort)\(self.method)\(self.password)\(self.remark)\(self.xProtocol)\(self.xProtocolParam)\(self.obfs)\(self.obfsParam)"
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}

func splitor(url: String) -> [String] {
    let regexp = "((ssr://)||(ss://))([A-Za-z0-9_-]+)"
    var ret: [String] = []
    var ssrUrl = url
    while ssrUrl.range(of:regexp, options: .regularExpression) != nil {
        let range = ssrUrl.range(of:regexp, options: .regularExpression)
        let result = String(ssrUrl[range!])
        ssrUrl.replaceSubrange(range!, with: "")
        ret.append(result)
    }
    return ret
}

func getLocalInfo() -> [String: Any] {
    let InfoDict = Bundle.main.infoDictionary
    return InfoDict!
}
