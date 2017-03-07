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
    var middleContent = NSRect.zero
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
        let imageViewController = mainStoryboard.instantiateController(withIdentifier: "imageViewController") as! NSViewController
        self.insertChildViewController(imageViewController, at: 1)
        let collectionViewController = mainStoryboard.instantiateController(withIdentifier: "collectionViewController") as! CollectionViewController
        self.insertChildViewController(collectionViewController, at: 2)
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
        let imageViewController = self.childViewControllers[1]
        let collectionViewController = self.childViewControllers[2]
        let containerWindow = self.view.window!
        containerWindow.delegate = self
        var leftFrame = NSRect.zero
        var middleFrame = NSRect.zero
        var rightFrame = NSRect.zero
        // divide main frame in 2 : 8 ratio
        var width = mainFrame.size.width / 5
        NSDivideRect(mainFrame, &leftFrame, &middleFrame, width, .minX)
        mainContent = containerWindow.contentRect(forFrameRect: mainFrame)
        let leftContent = containerWindow.contentRect(forFrameRect: leftFrame)
        // divide middle Frame in 0.42 : 0.58 ratio
        width = middleFrame.size.width * 0.42
        NSDivideRect(middleFrame, &middleFrame, &rightFrame, width, .minX)
        middleContent = containerWindow.contentRect(forFrameRect: middleFrame)
        rightContent = containerWindow.contentRect(forFrameRect: rightFrame)
        self.view.addSubview(outlineViewController.view)
        self.view.addSubview(collectionViewController.view)
        self.view.addSubview(imageViewController.view)
        outlineViewController.view.animator().frame = leftContent
        collectionViewController.view.animator().frame = middleContent
        imageViewController.view.animator().frame = rightContent
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
            guard let imageFileItem = imageFileItems?[index]
                else { return }
            // try pdf document
            if imageFileItem.isPDF {
                if let pdfImageRep = NSPDFImageRep(data: graphicsData) {
                    let pageCount = pdfImageRep.pageCount
                    for i in 0..<pageCount {
                        // make image for each page
                        pdfImageRep.currentPage = i
                        var pageRect = pdfImageRep.bounds
                        // now convert PDFImageRep to BitmapImageRep
                        let cgImage = pdfImageRep.cgImage(forProposedRect: &pageRect, context: nil, hints: [NSImageHintInterpolation: NSImageInterpolation.default.rawValue])
                        let imageRep = NSBitmapImageRep(cgImage: cgImage!)
                        imageBitmaps.append(imageRep)
                    }
                }
            }
            // only eps data are remaining at this point
            if (NSEPSImageRep(data: graphicsData) != nil) {
                if let epsImageRep = NSEPSImageRep(data: graphicsData) {
                    // EPS contains always only one page
                    var pageRect = epsImageRep.boundingBox
                    // now convert EPSImageRep to BitmapImageRep
                    let cgImage = epsImageRep.cgImage(forProposedRect: &pageRect, context: nil, hints: [NSImageHintInterpolation: NSImageInterpolation.default.rawValue])
                    let imageRep = NSBitmapImageRep(cgImage: cgImage!)
                    imageBitmaps.append(imageRep)
                }
            }
        }
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
        let destinationController = self.childViewControllers[2]
        let imageSubview = destinationController.view.subviews[1] as! NSImageView
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
        let controller = self.childViewControllers[2]
        controller.performSegue(withIdentifier: "CollectionViewSegue", sender: controller)
    }
    
    // MARK: - Methods for window delegate
    func windowWillEnterFullScreen(_ notification: Notification) {
        inFullScreen = true
        let outlineController = self.childViewControllers[0]
        let imageController = self.childViewControllers[1]
        let controller = self.childViewControllers[2]
        // check if controller is of class collection view controller
        if (controller is CollectionViewController) {
            outlineController.view.removeFromSuperview()
            imageController.view.removeFromSuperview()
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
        let imageController = self.childViewControllers[1]
        let controller = self.childViewControllers[2]
        // check if controller is of class collection view controller
        if (controller is CollectionViewController) {
            self.view.addSubview(outlineController.view)
            // set frame of collection view
            controller.view.frame = middleContent
            self.view.addSubview(imageController.view)
        }
        else {
            // set image view origin back to zero
            controller.view.setFrameOrigin(NSPoint.zero)
        }
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        // window did exit full screen mode
        let containerWindow = self.view.window!
        let controller = self.childViewControllers[2]
        let frameRect = (controller is CollectionViewController) ? mainFrame! : viewFrame
        containerWindow.setFrame(frameRect, display: true, animate: true)
    }

}
