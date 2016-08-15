//
//  AboutWindowController.swift
//  TPushTester
//
//  Created by uwei on 6/17/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {

    @IBOutlet weak var logo: NSImageView!
    override func windowDidLoad() {
        super.windowDidLoad()

        logo.image = NSImage(named: "logo")
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
