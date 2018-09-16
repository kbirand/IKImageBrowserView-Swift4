//
//  PreviewWindow.swift
//  IKImageBrowserView
//
//  Created by rock on 7/16/15.
//  Copyright (c) 2015 rock. All rights reserved.
//

import Cocoa

class PreviewWindow: NSWindow {

    @IBOutlet weak var browserController: ImageBrowserController!
    
    override func keyDown(with theEvent: NSEvent) {
        self.browserController.keyDown(with: theEvent)
    }
}
