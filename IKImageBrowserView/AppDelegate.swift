//
//  AppDelegate.swift
//  IKImageBrowserView
//
//  Created by rock on 7/15/15.
//  Copyright (c) 2015 rock. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var imageBrowserController: ImageBrowserController!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        //print(self.imageBrowserController)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    

}

