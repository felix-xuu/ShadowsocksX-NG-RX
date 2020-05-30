//
//  PingClient.swift
//  ShadowsocksX-R
//
//  Created by 称一称 on 16/9/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import SwiftyJSON

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
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
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
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        status = task.terminationStatus
        return (output, error, status)
    }
    
    func getlatencyFromString(result:String, type:String) -> String?{
        var res = result
        finished += 1
        var latency:String?=nil
        if type=="ss" {
            if result.isEmpty {
                return nil
            }
            latency = res.components(separatedBy: ".")[0]
        }else{
            if !result.contains("round-trip min/avg/max/stddev =") {
                return nil
            }
            res.removeSubrange(res.range(of: "round-trip min/avg/max/stddev = ")!)
            res = String(res.dropLast(3))
            latency = res.components(separatedBy: "/")[1].components(separatedBy: ".")[0]
        }
        return latency
    }
    
    func pingSingleHost(host:String,v2host:String,port:UInt16,localPort:UInt16,method:String,password:String ,completionHandler:@escaping (String?) -> Void){
        DispatchQueue.global(qos: .userInteractive).async {
            if v2host != "" {
                if let outputString = self.runCommand(cmd: "/sbin/ping", args: "-c", "1", "-t", "3", v2host).output.last{
                    completionHandler(self.getlatencyFromString(result: outputString,type: "v2"))
                }
            }else{
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
                    completionHandler(self.getlatencyFromString(result: outputString,type: "ss"))
                }
            }
        }
    }
    
    func ping(_ i: Int=0) {
        startTime = Date()
        po = 1100
        var result: [(Int, Int, Double)] = []
        for k in 0..<ServerGroupManager.serverGroups.count {
            let profiles = ServerGroupManager.serverGroups[k].serverProfiles
            for j in 0..<profiles.count {
                total += 1
                po = po + 1
                let host = profiles[j].serverHost
                let v2host=profiles[j].host
                let port = profiles[j].serverPort
                let method = profiles[j].method
                let password = profiles[j].password
                pingSingleHost(host: host,v2host: v2host,port: port,localPort: po,method: method,password: password, completionHandler: {
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
        usleep(useconds_t(1 * 1000 * 1000))
        let defaults = UserDefaults.standard
        let op = runCommand(cmd: "/usr/bin/curl", args: "-m", "5", "--socks5", defaults.string(forKey: UserKeys.Socks5_ListenAddress)!+":"+defaults.string(forKey: UserKeys.Socks5_ListenPort)!, "ipinfo.io").output.joined()
        let json = JSON(op.data(using: String.Encoding.utf8) ?? Data())
        var location = " -"
        if let city = json["city"].string{
            location = city
            if let country = json["country"].string{
                location = location + " (" + country + ")"
            }
        }
        return location
    }
}
