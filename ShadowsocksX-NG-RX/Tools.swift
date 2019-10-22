//
//  Tools.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/9/29.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyJSON

func ScanQRCodeOnScreen() {
    var displays: UnsafeMutablePointer<CGDirectDisplayID>? = nil
    var dspCount = CGDisplayCount(0)
    var rs: CGError

    rs = CGGetActiveDisplayList(0, nil, &dspCount)
    if rs != CGError.success {
        print("error: \(rs)")
        return
    }
    displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(dspCount))
    rs = CGGetActiveDisplayList(dspCount, displays, &dspCount)
    if rs != CGError.success {
        print("error: \(rs)")
        return
    }

    let detector = CIDetector.init(ofType: "CIDetectorTypeQRCode", context: CIContext.init(options: [CIContextOption.useSoftwareRenderer : true]), options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])

    var urls = [URL]()
    for i in 1...dspCount {
        let image: CGImage? = CGDisplayCreateImage(displays![Int(i - 1)])
        if image != nil {
            let features = (detector?.features(in: CIImage.init(cgImage: image!)))!
            for item in features {
                if let feature = (item as! CIQRCodeFeature).messageString {
                    if feature.hasPrefix(UserKeys.SSPrefix) || feature.hasPrefix(UserKeys.SSRPrefix) || feature.hasPrefix(UserKeys.VmessPrefix) {
                        urls.append(URL.init(string: feature)!)
                    }
                }
            }
        }
    }
    free(displays)
    NotificationCenter.default.post(
    name: Notification.Name(rawValue: NOTIFY_FOUND_SS_URL), object: nil
    , userInfo: [
        "urls": urls,
        "source": "qrcode"
    ])
}

func decode64(str: String) -> String {
    var string = str
    string = string.replacingOccurrences(of: "-", with: "+")
    string = string.replacingOccurrences(of: "_", with: "/")
    if string.count % 4 != 0 {
        let length = (4 - string.count % 4) + string.count;
        string = string.padding(toLength: length, withPad: "=", startingAt: 0)
    }
    if let data = Data(base64Encoded: string) {
        return String(data: data, encoding: .utf8) ?? ""
    }
    return ""
}

func encode64(str: String) -> String {
    if let data = str.data(using: .utf8) {
        var encodeStr = data.base64EncodedString()
        encodeStr = encodeStr.replacingOccurrences(of: "+", with: "-")
        encodeStr = encodeStr.replacingOccurrences(of: "/", with: "_")
        encodeStr = encodeStr.replacingOccurrences(of: "=", with: "")
        return encodeStr
    }
    return ""
}

func ParseAppURLSchemes(url: URL) -> [String : AnyObject]? {
    if url.host != nil {
        let str = url.absoluteString
        if str.hasPrefix(UserKeys.SSPrefix) {
            print(str.index(str.startIndex, offsetBy: 5))
            return ParseSSURL(urlString: str.replacingOccurrences(of: UserKeys.SSPrefix, with: ""))
        } else if str.hasPrefix(UserKeys.SSRPrefix) {
            return ParseSSRURL(urlString: str.replacingOccurrences(of: UserKeys.SSRPrefix, with: ""))
        } else if str.hasPrefix(UserKeys.VmessPrefix) {
            return ParseV2URL(urlString: str.replacingOccurrences(of: UserKeys.VmessPrefix, with: ""))
        }
    }
    return nil
}

// ss:// + base64(method:password@host:port)
func ParseSSURL(urlString: String) -> [String : AnyObject] {
    var dic = [String : AnyObject]()
    let decodeStr = decode64(str: urlString)
    
    let firstColonIndex = decodeStr.firstIndex(of: ":")!
    let atIndex = decodeStr.firstIndex(of: "@")!
    let lastColonIndex = decodeStr.lastIndex(of: ":")!
    
    dic["Method"] = decodeStr[..<firstColonIndex] as AnyObject
    dic["Password"] = decodeStr[decodeStr.index(firstColonIndex, offsetBy: 1)..<atIndex] as AnyObject
    dic["ServerHost"] = decodeStr[decodeStr.index(atIndex, offsetBy: 1)..<lastColonIndex] as AnyObject
    dic["ServerPort"] = Int(decodeStr[decodeStr.index(lastColonIndex, offsetBy: 1)...]) as AnyObject
    dic["url"] = UserKeys.SSPrefix + urlString as AnyObject
    
    return dic
}

// ssr:// + base64(host:port:protocol:encrypt:obfs:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
func ParseSSRURL(urlString: String) -> [String : AnyObject] {
    var dic = [String : AnyObject]()
    let decodeStr = decode64(str: urlString)
    var preStr, lastStr: String?
    
    if let interrIndex = decodeStr.firstIndex(of: "?") {
        preStr = String(decodeStr[..<decodeStr.index(interrIndex, offsetBy: -1)])
        lastStr = String(decodeStr[decodeStr.index(interrIndex, offsetBy: 1)...])
    } else {
        preStr = decodeStr
    }
    
    let preArr = preStr!.split(separator: ":")
    if preArr.count < 6 {
        return dic
    }
    
    dic["ServerHost"] = preArr[0] as AnyObject
    dic["ServerPort"] = Int(preArr[1]) as AnyObject
    dic["xProtocol"] = preArr[2] as AnyObject
    dic["Method"] = preArr[3] as AnyObject
    dic["obfs"] = preArr[4] as AnyObject
    dic["Password"] = decode64(str: String(preArr[5])) as AnyObject
    
    if lastStr != nil {
        let lastArr: [Substring] = lastStr!.split(separator: "&")
        for item in lastArr {
            if let equalIndex = item.firstIndex(of: "=") {
                dic[String(item[..<equalIndex])] = decode64(str: String(item[item.index(equalIndex, offsetBy: 1)...])) as AnyObject
            }
        }
    }
    dic["url"] = UserKeys.SSRPrefix + urlString as AnyObject
    return dic
}

// vmess:// + base64({"host":"","path":"","tls":"","add":"","port":1000,"aid":1,"net":"","type":"","v":"2","ps":"","id":""})
func ParseV2URL(urlString: String) -> [String : AnyObject] {
    var dic = [String : AnyObject]()
    let decodeStr = decode64(str: urlString)
    let json = JSON(parseJSON: decodeStr)
    dic["v"] = json["v"].string as AnyObject
    dic["ServerHost"] = json["add"].string as AnyObject
    dic["ServerPort"] = json["port"].intValue as AnyObject
    dic["host"] = json["host"].string as AnyObject
    dic["path"] = json["path"].string as AnyObject
    dic["tls"] = json["tls"].string as AnyObject
    dic["id"] = json["id"].string as AnyObject
    dic["aid"] = json["aid"].stringValue as AnyObject
    dic["net"] = json["net"].string as AnyObject
    dic["type"] = json["type"].string as AnyObject
    dic["remarks"] = json["ps"].string as AnyObject
    dic["url"] = UserKeys.VmessPrefix + urlString as AnyObject
    return dic
}
