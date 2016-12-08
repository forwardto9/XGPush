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

     private  var t:NSWindowController!
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let app = NSApplication.sharedApplication()
        let menu = app.mainMenu
        let items = menu?.itemArray
        for it in items! {
            let m = it.submenu
            let i = m?.itemArray
            for item in i! {
                if item.title == "About TPushTester" {
                    item.target = self;
                    item.action = #selector(self.showAbout)
                }
            }
        }
        
        MTAPro.startWithAppKey("INV5D6C3E7NR")
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func showAbout() -> Void {
        print("ShowAbout")
        t = NSWindowController(windowNibName: "AboutWindowController")
        t.showWindow(self)
    }
    
    
}

