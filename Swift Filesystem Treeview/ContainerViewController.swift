//
//  ContainerViewController.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster February 6, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class ContainerViewController: NSViewController, NSWindowDelegate {
    
    // MARK: - Constants for additional menu items
    let titles = ["Page Up", "Page Down", "Next Image", "Previous Image", "Back"]
    // strange enough, you do not need the class prefix containerViewController
    let selectors = [
        NSSelectorFromString("sheetUp:"),
        NSSelectorFromString("sheetDown:"),
        NSSelectorFromString("nextImage:"),
        NSSelectorFromString("previousImage:"),
        NSSelectorFromString("backToCollection:")
    ]
    // Int values of keys
    let keys = [NSUpArrowFunctionKey, NSDownArrowFunctionKey, NSRightArrowFunctionKey, NSLeftArrowFunctionKey, NSBackspaceCharacter]
    
    // MARK: - Properties
    var defaultSession: URLSession!
    var mainFrame: NSRect!
    var mainContent: NSRect!
    var rightContent = NSRect.zero
    
    var imageBitmaps = [NSImageRep]()
    var imageFileItems: [FileSystemItem]? = nil
    var imageFileIndex: Int = -1
    var inFullScreen = false
    
    var navigate: NSMenu {
        let menu = NSMenu(title: "Navigate")
        var i = 0
        for (key, selector) in zip(keys, selectors) {
            let keyScalar = UnicodeScalar(key)
            let keyChar = Character(keyScalar!)
            let item = NSMenuItem(title: titles[i], action: selector, keyEquivalent: String(keyChar))
            item.keyEquivalentModifierMask = []
            menu.addItem(item)
            if (i == 3) || (i == 1) {
                menu.addItem(NSMenuItem.separator())
            }
            i += 1
        }
        return menu
    }

    var pageIndex: Int = 0
    var viewFrame = NSRect.zero
    
    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
        // to use url request
        let config = URLSessionConfiguration.default
        self.defaultSession = URLSession(configuration: config)
        // instantiate source view controller
        let mainStoryboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        let outlineViewController = mainStoryboard.instantiateController(withIdentifier: "outlineViewController") as! OutlineViewController
        self.insertChildViewController(outlineViewController, at: 0)
        let collectionViewController = mainStoryboard.instantiateController(withIdentifier: "collectionViewController") as! CollectionViewController
        self.insertChildViewController(collectionViewController, at: 1)
        let presentationOptions: NSApplicationPresentationOptions = [.hideDock, .autoHideMenuBar]
        NSApp.presentationOptions = presentationOptions
        // get dimensions for view frame
        guard let visibleFrame = NSScreen.main()?.visibleFrame
            else { return }
        self.mainFrame = visibleFrame
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // now window exists
        let outlineViewController = self.childViewControllers[0]
        let collectionViewController = self.childViewControllers[1]
        let containerWindow = self.view.window!
        containerWindow.delegate = self
        var leftFrame = NSRect.zero
        var rightFrame = NSRect.zero
        let width = mainFrame.size.width
        // divide main frame in 3 : 7 ratio
        NSDivideRect(mainFrame, &leftFrame, &rightFrame, width*0.3, .minX)
        mainContent = containerWindow.contentRect(forFrameRect: mainFrame)
        let leftContent = containerWindow.contentRect(forFrameRect: leftFrame)
        rightContent = containerWindow.contentRect(forFrameRect: rightFrame)
        self.view.addSubview(outlineViewController.view)
        self.view.addSubview(collectionViewController.view)
        outlineViewController.view.animator().frame = leftContent
        collectionViewController.view.animator().frame = rightContent
        // set frame for container view window
        containerWindow.setFrame(mainFrame, display: true, animate: true)
    }
    
    // MARK: - Image routines
    func imageViewfromImageFileIndex(_ imageFileIndex: Int) {
        let imageFileItem = imageFileItems?[imageFileIndex]
        let imageURL = imageFileItem?.fileURL
        let urlRequest: URLRequest = URLRequest(url: imageURL!)
        let task = defaultSession.dataTask(with: urlRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error != nil {
                Swift.print("error from data task: \(error!.localizedDescription) in \((error as! NSError).domain)")
                return
            }
            else {
                DispatchQueue.main.async {
                    self.fillBitmaps(with: data!, at: imageFileIndex)
                    self.imageViewWithBitmap()
                }
            }
        })
        task.resume()
    }
    
    // generate representation(s) for image
    func fillBitmaps(with graphicsData: Data, at index: Int) {
        // generate representation(s) for image
        if (imageBitmaps.count > 0) {
            // make room for new bitmaps
            imageBitmaps.removeAll(keepingCapacity: false)
        }
        pageIndex = 0
        imageBitmaps = NSBitmapImageRep.imageReps(with: graphicsData)
        if (imageBitmaps.count == 0) {
            // convert pdf and eps image rep to bitmap image rep
            let fileType = imageFileItems?[index].type
            // try pdf document
            if fileType == "com.adobe.pdf" {
                if let pdfImageRep = NSPDFImageRep(data: graphicsData) {
                    let pageCount = pdfImageRep.pageCount
                    for i in 0..<pageCount {
                        // make image for each page
                        pdfImageRep.currentPage = i
                        // fill image rect with white background
                        let image = NSImage(size: pdfImageRep.size, flipped: false, drawingHandler:
                            {   (rect: NSRect) in
                            // set fill color
                            NSColor.white.setFill()
                            NSRectFill(rect)
                            pdfImageRep.draw(in: rect)
                            return true
                        })
                        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:])
                        let imageRep = NSBitmapImageRep(cgImage: cgImage!)
                        imageBitmaps.append(imageRep)
                    }
                }
            }
            // only eps data are remaining at this point
            if (NSEPSImageRep(data: graphicsData) != nil) {
                if let epsImageRep = NSEPSImageRep(data: graphicsData) {
                    // EPS contains always only one page
                    // fill image rect with white background
                    let image = NSImage(size: epsImageRep.size, flipped: false, drawingHandler:
                        {   (rect: NSRect) in
                            // set fill color
                            NSColor.white.setFill()
                            NSRectFill(rect)
                            epsImageRep.draw(in: rect)
                            return true
                    })
                    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:])
                    let imageRep = NSBitmapImageRep(cgImage: cgImage!)
                    imageBitmaps.append(imageRep)
                }
            }
        }
    }
    
    func size(imageRep: NSImageRep, in rect: NSRect) -> NSImageRep {
        let image = NSImage(size: rect.size)
        image.addRepresentation(imageRep)
        
        image.lockFocus()
        // fill bitmap with white background
        NSColor.white.setFill()
        NSRectFill(rect)
        // draw image over the background
        image.draw(in: rect)
        image.unlockFocus()
        
        return image.representations.first!
    }
    
    // look also at <https://blog.alexseifert.com/2016/06/18/resize-an-nsimage-proportionately-in-swift/>
    func fitImageIntoFrameRespectingAspectRatio(_ size: NSSize, into frame: NSRect) -> NSRect {
        var frameOrigin = NSPoint.zero
        var frameSize = frame.size
        // calculate aspect ratios
        let imageSize = size
        // calculate aspect ratios
        let mainRatio = frameSize.width / frameSize.height
        let imageRatio = imageSize.width / imageSize.height
        // fit view frame into main frame
        if (mainRatio > imageRatio) {
            // portrait, scale maxWidth
            let innerWidth = frameSize.height * imageRatio
            frameOrigin.x = (frameSize.width - innerWidth) / 2.0
            frameSize.width = innerWidth
        }
        else {
            // landscape, scale maxHeight
            let innerHeight = frameSize.width / imageRatio
            frameOrigin.y = (frameSize.height - innerHeight) / 2.0
            frameSize.height = innerHeight
        }
        return NSRect(origin: frameOrigin, size: frameSize)
    }
    
    func imageViewWithBitmap() {
        let destinationController = self.childViewControllers[1]
        let imageSubview = destinationController.view.subviews[0] as! NSImageView
        let imageItemFile = imageFileItems?[imageFileIndex]
        if (imageBitmaps.count > 0) {
            let imageBitmap = imageBitmaps[pageIndex]
            // get the real imagesize in pixels
            let imageSize = NSSize(width: imageBitmap.pixelsWide, height: imageBitmap.pixelsHigh)
            var contentRect = mainContent!
            var imageRect = fitImageIntoFrameRespectingAspectRatio(imageSize, into: contentRect)
            // calculate view frame for image view and button
            viewFrame = imageRect
            if !inFullScreen {
                imageRect.origin = NSPoint.zero
            }
            imageSubview.frame = imageRect
            let image = NSImage()
            image.addRepresentations([imageBitmap])
            imageSubview.image = image
            let containerWindow = self.view.window!
            containerWindow.setTitleWithRepresentedFilename((imageItemFile?.name)!)
            //resize view controller
            contentRect.size = viewFrame.size
            destinationController.view.frame = contentRect
            // set frame for container view window
            let frameRect = containerWindow.frameRect(forContentRect: viewFrame)
            containerWindow.setFrame(frameRect, display: true, animate: true)
        }
    }
    
    // MARK: - Menu entries for cursor keys
    func sheetUp(_ sender: Any) {
        // show page up
        if (!imageBitmaps.isEmpty) {
            let nextIndex = pageIndex - 1
            if (nextIndex >= 0) {
                pageIndex = nextIndex
                imageViewWithBitmap()
            }
        }
    }
    
    func sheetDown(_ sender: Any) {
        // show page down
        if (imageBitmaps.count > 1) {
            let nextIndex = pageIndex + 1
            if (nextIndex < imageBitmaps.count) {
                pageIndex = nextIndex
                imageViewWithBitmap()
            }
        }
    }
    
    func nextImage(_ sender: Any) {
        if (imageFileIndex >= 0) {
            // test what is in next URL
            let nextIndex = imageFileIndex + 1
            if (nextIndex < (imageFileItems?.count)!) {
                imageFileIndex = nextIndex
                imageViewfromImageFileIndex(nextIndex)
            }
        }
    }
    
    func previousImage(_ sender: Any) {
        if (imageFileIndex >= 0) {
            // test what is in previuos URL
            let nextIndex = imageFileIndex - 1
            if (nextIndex >= 0) {
                imageFileIndex = nextIndex
                imageViewfromImageFileIndex(nextIndex)
            }
        }
    }
    
    func backToCollection(_ sender: Any) {
        let controller = self.childViewControllers[1]
        controller.performSegue(withIdentifier: "CollectionViewSegue", sender: controller)
    }
    
    // MARK: - Methods for window delegate
    func windowWillEnterFullScreen(_ notification: Notification) {
        inFullScreen = true
        let outlineController = self.childViewControllers[0]
        let controller = self.childViewControllers[1]
        // check if controller is of class collection view controller
        if (controller is CollectionViewController) {
            outlineController.view.removeFromSuperview()
            controller.view.frame = mainFrame
        }
        else {
            // set real image view origin
            controller.view.frame.origin = viewFrame.origin
        }
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        // window did exit full screen mode
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        // window will exit full screen mode
        inFullScreen = false
        let outlineController = self.childViewControllers[0]
        let controller = self.childViewControllers[1]
        // check if controller is of class collection view controller
        if (controller is CollectionViewController) {
            // set frame of collection view
            controller.view.frame = rightContent
            self.view.addSubview(outlineController.view)
        }
        else {
            // set image view origin back to zero
            controller.view.setFrameOrigin(NSPoint.zero)
        }
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        // window did exit full screen mode
        let containerWindow = self.view.window!
        let controller = self.childViewControllers[1]
        let frameRect = (controller is CollectionViewController) ? mainFrame! : viewFrame
        containerWindow.setFrame(frameRect, display: true, animate: true)
    }

}
