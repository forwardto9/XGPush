//
//  AppDelegate.swift
//  TPushTester
//
//  Created by uwei on 5/24/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Cocoa

let XGAccessIDKey = "XG.AccessID"
let XGAccountQQKey = "XG.Account.QQ"
let XGSecretKey    = "XG.SecretKey"
let XGiOSToken     = "XG.iOS.Token"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

     fileprivate  var t:NSWindowController!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let app = NSApplication.shared()
        let menu = app.mainMenu
        let items = menu?.items
        for it in items! {
            let m = it.submenu
            let i = m?.items
            for item in i! {
                if item.title == "About TPushTester" {
                    item.target = self;
                    item.action = #selector(self.showAbout)
                }
            }
        }
        
        MTAPro.start(withAppKey: "INV5D6C3E7NR")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func showAbout() -> Void {
        print("ShowAbout")
        t = NSWindowController(windowNibName: "AboutWindowController")
        t.showWindow(self)
    }
    
    
}

