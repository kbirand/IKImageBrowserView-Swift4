//
//  ImageBrowserController.swift
//  IKImageBrowserView
//
//  Created by rock on 7/15/15.
//  Copyright (c) 2015 rock. All rights reserved.
//

import Cocoa
import Quartz
import AppKit


class myImageObject: NSObject {
    
    var path : String = ""
    var fileName : String = ""
    var size : String = ""
    
    override func imageRepresentationType() -> String!
    {
        return IKImageBrowserPathRepresentationType
    }
    
    override func imageRepresentation() -> Any!
    {
        return path
    }
    
    override func imageUID() -> String! {
        return path
    }
    
    override func imageTitle() -> String! {
        return fileName
    }
    
    override func imageSubtitle() -> String! {
        return size
    }
}


extension NSPasteboard.PasteboardType {
    
    static let backwardsCompatibleFileURL: NSPasteboard.PasteboardType = {
        
        if #available(OSX 10.13, *) {
            return NSPasteboard.PasteboardType.fileURL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }
        
    } ()
    
}



class ImageBrowserController: NSWindowController{
    
    @IBOutlet weak var previewWindow: NSWindow!
    @IBOutlet weak var previewImageView: NSImageView!
    
    @IBOutlet weak var imageBrowser: IKImageBrowserView!
    @IBOutlet weak var filenameLabel: NSTextField!
    
    
    var images:NSMutableArray = []
    var importedImages:NSMutableArray = []
    var selectedFilePath:String = ""
    var selectedIndex:Int = -1
    
    func openFiles()->NSArray?
    {
        var panel:NSOpenPanel
        
        panel = NSOpenPanel()
        panel.isFloatingPanel = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        let i = panel.runModal()
        if (i == NSApplication.ModalResponse.OK)
        {
            return panel.urls as NSArray
        }
        return nil
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        
    }
    
    override func awakeFromNib() {
        images = []
        importedImages = []
        imageBrowser.setAllowsReordering(true)
        imageBrowser.setAnimates(true)
        imageBrowser.setDraggingDestinationDelegate(self)
        imageBrowser.setCellsStyleMask(IKCellsStyleOutlined|IKCellsStyleTitled|IKCellsStyleSubtitled)
        
    }
    
    func updateDatasource() {
        
        images.addObjects(from: importedImages as [AnyObject])
        importedImages.removeAllObjects()
        imageBrowser.reloadData()
        
    }
    
    func addAnImageWithPath(_ path: String) {
        let myURL = URL(fileURLWithPath: path)
        let fileExtension = myURL.pathExtension
        let fileUTI:Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        let isImage = UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
        
        if (isImage == false) {
            return
        }
        let p:myImageObject = myImageObject()
        p.path = path
        p.fileName = URL(fileURLWithPath: path).lastPathComponent
        p.size = {
            let imageReg : NSImageRep = NSImageRep(contentsOf: URL(fileURLWithPath: path))!
            let fileSize = "\(imageReg.pixelsWide) x \(imageReg.pixelsHigh)"
            return fileSize
        }()
        importedImages.add(p)
    }
    
    func addImagesWithPath(_ path: String, recursive:Bool) {
        
        var dir = ObjCBool(false)
        
        FileManager.default.fileExists(atPath: path, isDirectory: &dir)
        
        if dir.boolValue {
            let content:NSArray = try! FileManager.default.contentsOfDirectory(atPath: path) as NSArray
            let n = content.count
            
            for  i in 0...n-1 {
                let newPath = URL(fileURLWithPath: path).appendingPathComponent(content.object(at: i) as! String).path
                
                
                if recursive {
                    
                    self.addImagesWithPath(newPath, recursive:true)
                }
                else {
                    self.addAnImageWithPath(newPath)
                }
            }
        }
        else {
            self.addAnImageWithPath(path)
        }
    }
    
    func addImagesWithPaths(_ urls: NSArray) {
        
        
        let n = urls.count
        for i in 0...n-1 {
            let url:URL = urls.object(at: i) as! URL
            self.addImagesWithPath(url.path, recursive: false)
        }
        
        
        DispatchQueue.main.async(execute: {
            self.updateDatasource()
        })
    }
    
    
    @IBAction func addImageButtonClickedd(_ sender: NSButton) {
        let urls:NSArray? = openFiles()
        
        if urls == nil {
            print("No files selected, return...")
            return
        }
        
        
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            self.addImagesWithPaths(urls!)
            DispatchQueue.main.async(execute: { () -> Void in
            })
        })
    }
    
    @IBAction func zoomSliderDidChange(_ sender: NSSlider) {
        imageBrowser.setZoomValue(sender.floatValue)
        imageBrowser.needsDisplay = true
    }
    
    @IBAction func getFiles(_ sender: Any) {
        
        let selects = imageBrowser.selectionIndexes() as IndexSet
        
        if selects.isEmpty  {
            print("no files selected...")
            return
        }
        
        print("selected files found...")
        
        for items in selects {
            let myFilePath = images.object(at: items) as! myImageObject
            print(myFilePath.path)
        }
    
    }
    
    
    
    override func numberOfItems(inImageBrowser view: IKImageBrowserView) -> Int {
        return images.count
    }
    
    override func imageBrowser(_ aBrowser: IKImageBrowserView!, itemAt index: Int) -> Any! {
        return images.object(at: index)
    }
    
    
    override func imageBrowser(_ aBrowser: IKImageBrowserView!, removeItemsAt indexes: IndexSet!) {
        images.removeObjects(at: indexes)
    }
    
    
    
    override func imageBrowser(_ aBrowser: IKImageBrowserView!, moveItemsAt indexes: IndexSet!, to destinationIndex: Int) -> Bool {
        let temporaryArray:NSMutableArray = []
        var destinationIdx: Int = destinationIndex
        
        var index = indexes.last
        
        while index != nil {
            if index! < destinationIdx {
                destinationIdx -= 1
            }
            
            let obj: AnyObject = images.object(at: index!) as AnyObject
            temporaryArray.add(obj)
            images.removeObject(at: index!)
            index = indexes.integerLessThan(index!)
        }
        
        let n = temporaryArray.count
        for index in 0...n-1 {
            images.insert(temporaryArray.object(at: index), at: destinationIdx)
        }
        
        return true
    }
    
    override func imageBrowserSelectionDidChange(_ aBrowser: IKImageBrowserView!) {
        let indexes = aBrowser.selectionIndexes()
        
        if (indexes?.count == 0) {
            self.filenameLabel.stringValue = "No selected file"
            selectedFilePath = ""
            selectedIndex = -1
        }
        else if (indexes?.count == 1) {
            let idx = indexes?.last
            let obj:myImageObject = images.object(at: idx!) as! myImageObject
            let path:String = obj.path
            let myURL = URL(fileURLWithPath: path)
            self.filenameLabel.stringValue = myURL.pathComponents.last!
            selectedFilePath = path
            selectedIndex = idx!
        }
        else {
            let filename:String = String("\(indexes!.count) files selected")
            self.filenameLabel.stringValue = filename
            
            let idx = indexes?.last
            let obj:myImageObject = images.object(at: idx!) as! myImageObject
            let path:String = obj.path
            selectedFilePath = path
            selectedIndex = idx!
        }
    }
    
    // key handle
    
    //    override func keyDown(with theEvent: NSEvent) {
    //        print(theEvent.keyCode)
    //
    //        if theEvent.keyCode == 49 { // if it is space key,
    //            if (self.selectedFilePath.isEmpty) {
    //                return
    //            }
    //
    //            print(self.selectedFilePath)
    //
    //            self.openPreviewWindow(selectedFilePath)
    //
    //
    //        }
    //        else if theEvent.keyCode == 53
    //        {
    //            if (self.previewWindow.isVisible)
    //            {
    //                self.previewWindow.close()
    //                self.window?.makeKeyAndOrderFront(self)
    //            }
    //        }
    //        else if theEvent.keyCode == 123 // left arrow
    //        {
    //            if (self.selectedIndex - 1 <= 0) {
    //                return
    //            }
    //
    //            var idx = selectedIndex -= 1
    //            var obj:myImageObject = images.object(at: idx) as! myImageObject
    //            var path:String = obj.path
    //
    //            self.openPreviewWindow(path)
    //        }
    //        else if theEvent.keyCode == 124 // right arrow
    //        {
    //            if (self.selectedIndex < 0 || selectedIndex + 1 >= images.count) {
    //                return
    //            }
    //
    //            var idx = selectedIndex += 1
    //            var obj:myImageObject = images.object(at: idx) as! myImageObject
    //            var path:String = obj.path
    //
    //            self.openPreviewWindow(path)
    //        }
    //    }
    
    func openPreviewWindow(_ path:String)
    {
        self.previewImageView.image = NSImage(byReferencingFile: path)
        
        if (self.previewImageView.image == nil)
        {
            return
        }
        
        let size:NSSize! = self.previewImageView.image?.size
        
        let screenSize:NSSize! = NSScreen.main?.frame.size
        
        var width = size.width
        var height = size.height
        
        if (width > screenSize.width) {
            height = height * screenSize.width / width
            width = screenSize.width
        }
        if (height > screenSize.height) {
            width = width * screenSize.height / height
            height = screenSize.height
        }
        
        var rect:NSRect = self.previewWindow.frame
        rect.origin.x = (screenSize.width - width) / 2
        rect.origin.y = (screenSize.height - height) / 2
        rect.size.width = width
        rect.size.height = height
        self.previewWindow.setFrame(rect, display: false)
        
        self.previewWindow .makeKeyAndOrderFront(self)
        let myURL = URL(fileURLWithPath: path)
        self.previewWindow.title = myURL.lastPathComponent
    }
    
    
    func draggingEntered(_ sender: AnyObject) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    func draggingUpdated(_ sender: AnyObject) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var data:Data? = nil
        let pasteboard:NSPasteboard = sender.draggingPasteboard()
        
        let types:NSArray = pasteboard.types! as NSArray
        if (types.contains(NSPasteboard.PasteboardType.backwardsCompatibleFileURL)) {
            data = pasteboard.data(forType: NSPasteboard.PasteboardType.backwardsCompatibleFileURL)
        }
        
        if (data != nil) {
            
            let filenames:NSArray = try! PropertyListSerialization.propertyList(from: data!, options: [], format: nil) as! NSArray
            
            let n = filenames.count
            for i in 0...n {
                self.addAnImageWithPath(filenames.object(at: i) as! String)
            }
            
            self.updateDatasource()
        }
        
        return true
    }
}
