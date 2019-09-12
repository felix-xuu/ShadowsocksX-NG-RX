//
//  ProxyConfHelper.m
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/10.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#import "ProxyConfHelper.h"
#import "proxy_conf_helper_version.h"
#import "ShadowsocksX_NG_RX-Swift.h"

#define kShadowsocksHelper @"/Library/Application Support/ShadowsocksX-NG-RX/proxy_conf_helper"

@implementation ProxyConfHelper

GCDWebServer *webServer = nil;

+ (BOOL)isVersionOk {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];
    
    NSArray *args;
    args = [NSArray arrayWithObjects:@"-v", nil];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fd;
    fd = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [fd readDataToEndOfFile];
    
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (str.length != 0 && ![str isEqualToString:kProxyConfHelperVersion]) {
        return NO;
    }
    return YES;
}

+ (void)install {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kShadowsocksHelper] || ![self isVersionOk]) {
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"bash %@\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"install proxy_conf_helper successed");
        } else {
            NSLog(@"install proxy_conf_helper failed");
        }
    }
}

+ (void)callHelper:(NSArray*) arguments {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];

    // this log is very important
    NSLog(@"run shadowsocks helper: %@", kShadowsocksHelper);
    [task setArguments:arguments];

    NSPipe *stdoutpipe;
    stdoutpipe = [NSPipe pipe];
    [task setStandardOutput:stdoutpipe];

    NSPipe *stderrpipe;
    stderrpipe = [NSPipe pipe];
    [task setStandardError:stderrpipe];

    NSFileHandle *file;
    file = [stdoutpipe fileHandleForReading];

    [task launch];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }

    file = [stderrpipe fileHandleForReading];
    data = [file readDataToEndOfFile];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }
}

+ (void)addArguments4ManualSpecifyNetworkServices:(NSMutableArray*) args {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:UserKeys.AutoConfigureNetworkServices]) {
        NSArray* serviceKeys = [defaults arrayForKey:UserKeys.Proxy4NetworkServices];
        if (serviceKeys) {
            for (NSString* key in serviceKeys) {
                [args addObject:@"--network-service"];
                [args addObject:key];
            }
        }
    }
}

+ (void)enablePACProxy {
    [self disableProxy];
    //start server here and then using the string next line
    //next two lines can open gcdwebserver and work around pac file
    NSString *PACURLString = [self startPACServer];//hi 可以切换成定制pac文件路径来达成使用定制文件路径
    NSURL* url = [NSURL URLWithString: PACURLString];

    NSMutableArray* args = [@[@"--mode", @"pac", @"--pac-url", [url absoluteString]]mutableCopy];
    
    [self addArguments4ManualSpecifyNetworkServices:args];
    [self callHelper:args];
}

+ (void)enableGlobalProxy {
    [self disableProxy];
    NSUInteger port = [[NSUserDefaults standardUserDefaults]integerForKey:UserKeys.Socks5_ListenPort];
    
    NSMutableArray* args = [@[@"--mode", @"global", @"--port"
                              , [NSString stringWithFormat:@"%lu", (unsigned long)port]]mutableCopy];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UserKeys.HTTPOn] && [[NSUserDefaults standardUserDefaults] boolForKey:UserKeys.HTTP_FollowGlobal]) {
        NSUInteger privoxyPort = [[NSUserDefaults standardUserDefaults]integerForKey:UserKeys.HTTP_ListenPort];

        [args addObject:@"--privoxy-port"];
        [args addObject:[NSString stringWithFormat:@"%lu", (unsigned long)privoxyPort]];
    }
    
    [self addArguments4ManualSpecifyNetworkServices:args];
    [self callHelper:args];
}

+ (void)disableProxy {
//    带上所有参数是为了判断是否原有代理设置是否由ssx-ng设置的。如果是用户手工设置的其他配置，则不进行清空。
//    NSString* urlString = [NSString stringWithFormat:@"%@/.ShadowsocksX-NG/gfwlist.js", NSHomeDirectory()];
//    NSURL* url = [NSURL fileURLWithPath:urlString];
//    NSString *PACURLString = [self startPACServer: PACFilePath];//hi 可以切换成定制pac文件路径来达成使用定制文件路径
//    NSURL* url = [NSURL URLWithString: PACURLString];
//    NSUInteger port = [[NSUserDefaults standardUserDefaults]integerForKey:@"LocalSocks5.ListenPort"];
//
//    NSMutableArray* args = [@[@"--mode", @"off"
//                              , @"--port", [NSString stringWithFormat:@"%lu", (unsigned long)port]
//                              , @"--pac-url", [url absoluteString]
//                              ]mutableCopy];

    NSMutableArray* args = [@[@"--mode", @"off"]mutableCopy];
    [self addArguments4ManualSpecifyNetworkServices:args];
    [self callHelper:args];
    [self stopPACServer];
}

+ (NSString*)startPACServer {
    //接受参数为以后使用定制PAC文件
    NSData * originalPACData;
    NSString * routerPath = @"/proxy.pac";
    originalPACData = [NSData dataWithContentsOfFile: [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @".ShadowsocksX-NG-RX/gfwlist.js"]];
    webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path: routerPath requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
            return [GCDWebServerDataResponse responseWithData: originalPACData contentType:@"application/x-ns-proxy-autoconfig"];
        }
    ];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * address = [defaults stringForKey:UserKeys.PacServer_ListenAddress];
    int port = (int)[defaults integerForKey:UserKeys.PacServer_ListenPort];

    [webServer startWithOptions:@{@"BindToLocalhost":@YES, @"Port":@(port)} error:nil];

    return [NSString stringWithFormat:@"%@%@:%d%@",@"http://",address,port,routerPath];
}

+ (void)stopPACServer {
    if ([webServer isRunning]) {
        [webServer stop];
    }
}

@end
