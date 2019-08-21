//
//  QRCodeUtils.m
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/8.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "Utils.h"

void ScanQRCodeOnScreen() {
    /* displays[] Quartz display ID's */
    CGDirectDisplayID   *displays = nil;
    
    CGError             err = CGDisplayNoErr;
    CGDisplayCount      dspCount = 0;
    
    /* How many active displays do we have? */
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
    /* If we are getting an error here then their won't be much to display. */
    if (err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display count (%d)\n", err);
        return;
    }
    
    /* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
    // Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
    
    /* More error-checking here. */
    if (err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
    }
    
    NSMutableArray* foundSSUrls = [NSMutableArray array];
    
    CIDetector *detector = [CIDetector detectorOfType: @"CIDetectorTypeQRCode"
                                              context: [CIContext contextWithOptions: @{kCIContextUseSoftwareRenderer: @true}]
                                              options: @{ CIDetectorAccuracy:CIDetectorAccuracyHigh }];
    
    for (unsigned int displaysIndex = 0; displaysIndex < dspCount; displaysIndex++)
    {
        /* Make a snapshot image of the current display. */
        CGImageRef image = CGDisplayCreateImage(displays[displaysIndex]);
        NSArray *features = [detector featuresInImage: [CIImage imageWithCGImage: image]];
        for (CIQRCodeFeature *feature in features) {
            if ([feature.messageString hasPrefix: @"ss://"])
            {
                [foundSSUrls addObject: [NSURL URLWithString: feature.messageString]];
            } else if ([feature.messageString hasPrefix: @"ssr://"]){
                [foundSSUrls addObject: [NSURL URLWithString: feature.messageString]];
            }
        }
         CGImageRelease(image);
    }
    
    free(displays);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NOTIFY_FOUND_SS_URL"
     object:nil
     userInfo: @{ @"urls": foundSSUrls,
                  @"source": @"qrcode"
                 }
     ];
}

NSString* decode64(NSString* str){
    
    str = [str stringByReplacingOccurrencesOfString: @"-" withString: @"+"];
    str = [str stringByReplacingOccurrencesOfString: @"_" withString: @"/"];
    if(str.length % 4) {
        NSInteger length = (4 - str.length % 4) + str.length;
        str = [str stringByPaddingToLength: length withString: @"=" startingAtIndex:0];
    }
    NSData* decodeData = [[NSData alloc] initWithBase64EncodedString: str options:0];
    NSString* decodeStr = [[NSString alloc] initWithData: decodeData encoding:NSUTF8StringEncoding];
    return decodeStr;
}

NSString* encode64(NSString* str){
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSString *stringBase64 = [data base64EncodedStringWithOptions: NSDataBase64EncodingEndLineWithCarriageReturn];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString: @"+" withString: @"-"];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString: @"/" withString: @"_"];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString: @"=" withString: @""];
    return stringBase64;
}

NSDictionary<NSString*, id>* ParseAppURLSchemes(NSURL* url){
    if(!url.host) {
        return nil;
    }
    NSString *urlString = [url absoluteString];
    if ([urlString hasPrefix:@"ss://"]) {
        return ParseSSURL(url.host);
    } else if ([urlString hasPrefix:@"ssr://"]) {
        return ParseSSRURL(url.host);
    }
    return nil;
}

// ss:// + base64(method:password@domain:port)
static NSDictionary<NSString*, id>* ParseSSURL(NSString* urlString) {
    urlString = decode64(urlString);
    NSRange firstColonRange = [urlString rangeOfString: @":"];
    NSRange lastColonRange = [urlString rangeOfString: @":" options: NSBackwardsSearch];
    NSRange lastAtRange = [urlString rangeOfString: @"@" options: NSBackwardsSearch];

    NSString *method = [urlString substringWithRange: NSMakeRange(0, firstColonRange.location)];
    NSString *password = [urlString substringWithRange: NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
    NSString *IP = [urlString substringWithRange: NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
    NSString *port = [urlString substringWithRange: NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];

    return @{@"ServerHost": IP,
             @"ServerPort": @([port integerValue]),
             @"Method": method,
             @"Password": password,
             };
}

 // ssr:// + base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
static NSDictionary<NSString*, id>* ParseSSRURL(NSString* urlString) {
    NSString *firstParam;
    NSString *lastParam;
    NSString *decodedString = decode64(urlString);
    NSRange paramSplit = [decodedString rangeOfString: @"?"];

    if (paramSplit.length == 0){
        firstParam = decodedString;
    } else {
        firstParam = [decodedString substringToIndex:paramSplit.location - 1];
        lastParam = [decodedString substringFromIndex:paramSplit.location];
    }
    
    //后面已经parser完成，接下来需要解析到profile里面
    //abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}
    NSRange range = [firstParam rangeOfString: @":"];
    NSString *ip = [firstParam substringToIndex: range.location];//第一个参数是域名
    
    firstParam = [firstParam substringFromIndex: range.location + range.length];
    range = [firstParam rangeOfString: @":"];
    NSString *port = [firstParam substringToIndex: range.location];//第二个参数是端口
    
    firstParam = [firstParam substringFromIndex: range.location + range.length];
    range = [firstParam rangeOfString: @":"];
    NSString *xProtocol = [firstParam substringToIndex: range.location];//第三个参数是协议
    
    firstParam = [firstParam substringFromIndex: range.location + range.length];
    range = [firstParam rangeOfString: @":"];
    NSString *encryption = [firstParam substringToIndex: range.location];//第四个参数是加密
    
    firstParam = [firstParam substringFromIndex: range.location + range.length];
    range = [firstParam rangeOfString: @":"];
    NSString *obfs = [firstParam substringToIndex: range.location];//第五个参数是混淆协议
    
    firstParam = [firstParam substringFromIndex: range.location + range.length];

    NSString *password = decode64(firstParam);//第六个参数是base64密码
    
    NSString *obfsParam = @"";
    NSString *remarks = @"";
    NSString *xProtocolParam = @"";
    NSString *group = @"";
    NSDictionary *parserLastParamDict = parseSSRLastParam(lastParam);
    for (NSString *key in parserLastParamDict) {
        if ([key isEqual: @"obfsparam"]) {
            obfsParam = parserLastParamDict[key];
        } else if ([key isEqual: @"remarks"]) {
            remarks = parserLastParamDict[key];
        } else if([key isEqual: @"protoparam"]){
            xProtocolParam = parserLastParamDict[key];
        } else if([key isEqual: @"group"]){
            group = parserLastParamDict[key];
        }
    }
    return @{@"ServerHost": ip,
             @"ServerPort": @([port integerValue]),
             @"Method": encryption,
             @"Password": password,
             @"obfs": obfs,
             @"obfsParam": obfsParam,
             @"xProtocol": xProtocol,
             @"xProtocolParam": xProtocolParam,
             @"Remark": remarks,
             @"group": group,
             };
}

static NSDictionary<NSString*, id>* parseSSRLastParam(NSString* lastParam) {
    NSMutableDictionary *parserLastParamDict = [[NSMutableDictionary alloc]init];
    if(lastParam.length == 0){
        return nil;
    }
    lastParam = [lastParam substringFromIndex: 1];
    NSArray *lastParamArray = [lastParam componentsSeparatedByString: @"&"];
    for (int i=0; i<lastParamArray.count; i++) {
        NSString *toSplitString = lastParamArray[i];
        NSRange lastParamSplit = [toSplitString rangeOfString: @"="];
        if (lastParamSplit.location != NSNotFound) {
            NSString *key = [toSplitString substringToIndex:lastParamSplit.location];
            NSString *value = decode64([toSplitString substringFromIndex:lastParamSplit.location + 1]);
            [parserLastParamDict setValue: value forKey: key];
        }
    }
    return parserLastParamDict;
}
