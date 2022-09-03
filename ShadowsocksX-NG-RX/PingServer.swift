//
//  PingClient.swift
//  ShadowsocksX-R
//
//  Created by 称一称 on 16/9/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

class PingServers:NSObject {
    static let instance = PingServers()
    var po:UInt16 = 0
    var total:UInt16 = 0
    var finished:UInt16 = 0
    var startTime:Date?
    
    func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: .newlines)
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: .newlines)
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    func runCommand2(ssArgs:[String], cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        var status:Int32 = 0
        
        let ssTask = Process()
        ssTask.launchPath = NSHomeDirectory()+APP_SUPPORT_DIR+"ss-local"
        ssTask.arguments = ssArgs
        var environment =  ProcessInfo.processInfo.environment
        environment["DYLD_LIBRARY_PATH"] = NSHomeDirectory() + APP_SUPPORT_DIR
        ssTask.environment = environment
        ssTask.launch()
        ssTask.waitUntilExit()
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: .newlines)
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: .newlines)
        }
        
        task.waitUntilExit()
        status = task.terminationStatus
        return (output, error, status)
    }
    
    func getlatencyFromString(result:String) -> String?{
        finished += 1
        var latency:String?=nil
        if result.isEmpty {
            return nil
        }
        latency = result.components(separatedBy: ".")[0]
        return latency
    }
    
    func pingSingleHost(host:String,port:UInt16,localPort:UInt16,method:String,password:String ,completionHandler:@escaping (String?) -> Void){
        DispatchQueue.global(qos: .userInteractive).async {
            let path = NSHomeDirectory()+APP_SUPPORT_DIR+"httping"
            var ssArgs: [String] = []
            ssArgs.append("-s")
            ssArgs.append(host)
            ssArgs.append("-p")
            ssArgs.append(String(port))
            ssArgs.append("-k")
            ssArgs.append(password)
            ssArgs.append("-m")
            ssArgs.append(method)
            ssArgs.append("-l")
            ssArgs.append(String(localPort))
            ssArgs.append("--reuse-port")
            ssArgs.append("--fast-open")
            ssArgs.append("-f")
            ssArgs.append("sspid.txt")
            if let outputString = self.runCommand2(ssArgs: ssArgs,cmd: path, args: "-5", "-x", "127.0.0.1:"+String(localPort), "-g", "http://www.gstatic.com/generate_204", "-c","1","-t","3","-o","204","-m").output.last{
                completionHandler(self.getlatencyFromString(result: outputString))
            }
        }
    }
    
    func ping() {
        startTime = Date()
        po = 1100
        var result: [(Int, Int, Double)] = []
        for k in 0..<ServerGroupManager.serverGroups.count {
            let profiles = ServerGroupManager.serverGroups[k].serverProfiles
            for j in 0..<profiles.count {
                total += 1
                po = po + 1
                let host = profiles[j].serverHost
                let port = profiles[j].serverPort
                let method = profiles[j].method
                let password = profiles[j].password
                pingSingleHost(host: host,port: port,localPort: po,method: method,password: password, completionHandler: {
                    if let latency = $0 {
                        profiles[j].latency = latency
                    } else {
                        profiles[j].latency = "timeout"
                    }
                    if let active = ServerProfileManager.activeProfile {
                        if active.uuid == profiles[j].uuid {
                            ServerProfileManager.setActiveProfile(profiles[j])
                        }
                    }
                })
            }
        }
        DispatchQueue.global().async {
            while self.finished<self.total && Date().timeIntervalSince(self.startTime!)<30 {
                sleep(1)
            }
            
            for k in 0..<ServerGroupManager.serverGroups.count {
                let profiles = ServerGroupManager.serverGroups[k].serverProfiles
                for j in 0..<profiles.count {
                    if let late = profiles[j].latency {
                        if let latency = Double(late){
                            result.append((k, j, latency))
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
                
                if let min = result.min(by: {$0.2 < $1.2}){
                    let groupName = ServerGroupManager.serverGroups[min.0].groupName
                    notificationDeliver(title: "Done the ping, the fastest as follow", subTitle: "", text: "\(groupName)"
                        + " - \(ServerGroupManager.serverGroups[min.0].serverProfiles[min.1].remark)"
                        + " - \(ServerGroupManager.serverGroups[min.0].serverProfiles[min.1].latency!)ms")
                }
                let shPath = Bundle.main.path(forResource: "killPing", ofType: "sh")
                let task = Process.launchedProcess(launchPath: shPath!, arguments: [])
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    NSLog("clean ping succeeded.")
                } else {
                    NSLog("clean ping failed.")
                }
            }
        }
    }
    
    func getLocation() -> String {
        return ipLocation(url: "https://ipapi.co/json") ?? ipLocation(url: "https://ipinfo.io/json") ?? " -"
    }
    
    func ipLocation(url: String) -> String? {
        let defaults = UserDefaults.standard
        let op = runCommand(cmd: "/usr/bin/curl", args: "-m", "5", "--socks5", defaults.string(forKey: UserKeys.Socks5_ListenAddress)!+":"+defaults.string(forKey: UserKeys.Socks5_ListenPort)!, url).output.joined()
        print(op)
        var location: String?
        if let json = try? JSONSerialization.jsonObject(with: Data(op.utf8), options: []) as? [String:Any] {
            if let city = json["city"] as? String {
                location = city
                if let country = json["country"] as? String {
                    location = location! + " (" + country + ")"
                }
            }
        }
        return location
    }
    
    func pingCurrent() -> String? {
        if ServerProfileManager.activeProfile == nil {
            return nil
        }
        let path = NSHomeDirectory()+APP_SUPPORT_DIR+"httping"
        if let outputString = self.runCommand(cmd: path, args: "-5", "-x", "127.0.0.1:"+UserDefaults.standard.string(forKey: UserKeys.Socks5_ListenPort)!, "-g", "http://www.gstatic.com/generate_204", "-c","1","-t","3","-o","204","-m").output.last{
            return self.getlatencyFromString(result: outputString)
        }
        return nil
    }
}
