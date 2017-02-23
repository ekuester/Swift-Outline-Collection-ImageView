//
//  FileSystemItem.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on February 5, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class FileSystemItem: NSObject {
    
    let propertyKeys: [URLResourceKey] = [.localizedNameKey, .effectiveIconKey, .isDirectoryKey, .typeIdentifierKey]
    let resourceValueKeys: Set<URLResourceKey> = [.nameKey, .localizedNameKey, .effectiveIconKey, .isDirectoryKey, .typeIdentifierKey]
    
    var fileURL: URL
    var resourceValues: URLResourceValues?
    
    var name: String? {
        return resourceValues?.name
    }
    
    var localizedName: String? {
        return resourceValues?.localizedName
    }
    
    var icon: NSImage! {
        let resourceValues = try! fileURL.resourceValues(forKeys: [.effectiveIconKey])
        return resourceValues.effectiveIcon as? NSImage
    }
/*
    var dateOfCreation: Date! {
        return resourceValues.creationDate
    }
    
    var dateOfLastModification: Date! {
        return resourceValues.contentAccessDate
    }
 */
    var type: String? {
        return resourceValues?.typeIdentifier
    }
    
    var isDirectory: Bool? {
        return resourceValues?.isDirectory
    }
    
    var isImageFile: Bool {
        return UTTypeConformsTo(type as! CFString, kUTTypeImage)
    }
    
    var parent: FileSystemItem? = nil
    var children: [FileSystemItem] {
        var childs: [FileSystemItem] = []
        let fileManager = FileManager.default
        // show no hidden Files (if you want this, remove // on out next line)
        let options: FileManager.DirectoryEnumerationOptions =
            [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
        //        var directoryURL = ObjCBool(false)
        let validURL = fileManager.fileExists(atPath: fileURL.relativePath)
        if (validURL && self.isDirectory!) {
            // contents of directory
            do {
                let childURLs = try
                    fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: propertyKeys, options: options)
                for childURL in childURLs {
                    let child = FileSystemItem(url: childURL)
                    childs.append(child)
                }
            }
            catch {
                print("Unexpected error occured: \(error).")
            }
        }
    return childs
    }

    func hasChildren() -> Bool {
        return (self.isDirectory! && (self.children.count > 0))
    }
    
    // adapted from <https://blog.alexseifert.com/2016/06/18/resize-an-nsimage-proportionately-in-swift/>
    func sizeImage(_ image:NSImage?, into size: CGSize) -> NSImage? {
        // not necessary, collection view resizes much mor quicker
        if let image = image {
            var imageRect = CGRect.zero
            imageRect.size = image.size
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:])
            let imageAspectRatio = image.size.width / image.size.height
            // resize dimensions for new image
            var newSize = size
            if (imageAspectRatio > 1.0) {
                newSize.height = size.width / imageAspectRatio
            }
            else {
                newSize.width = size.height * imageAspectRatio
            }
            // Create new image from CGImage using new size
            return NSImage(cgImage: cgImage!, size: newSize)
        }
        return nil
    }
    
    // thumbnail from image file at url
    var thumbnail: NSImage? {
        switch self.type {
        case "com.adobe.pdf"?:
            do {
                let pdfData = try Data(contentsOf: self.fileURL)
                if let pdfImageRep = NSPDFImageRep(data: pdfData) {
                    // make image for first page
                    pdfImageRep.currentPage = 0
                    let imageRect = NSRectToCGRect(pdfImageRep.bounds)
                    // fill image rect with white background
                    let image = NSImage(size: imageRect.size, flipped: false, drawingHandler:
                        {   (rect: CGRect) in
                            // set fill color
                            NSColor.white.setFill()
                            NSRectFill(rect)
                            pdfImageRep.draw(in: rect)
                            return true
                    })
                    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:])
                    return NSImage(cgImage: cgImage!, size: imageRect.size)
                }
            }
            catch let error as NSError {
                print("error reading pdf: \(error.localizedDescription) in \(error.domain)")
            }
        case "com.adobe.encapsulated-postscript"?:
            // eps documents have per definitionem one page
            do {
                let epsData = try Data(contentsOf: self.fileURL)
                if let epsImageRep = NSEPSImageRep(data: epsData) {
                    let imageRect = NSRectToCGRect(epsImageRep.boundingBox)
                    // fill image rect with white background
                    let image = NSImage(size: imageRect.size, flipped: false, drawingHandler:
                        {   (rect: CGRect) in
                            // set fill color
                            NSColor.white.setFill()
                            NSRectFill(rect)
                            epsImageRep.draw(in: rect)
                            return true
                    })
                    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:])
                    return NSImage(cgImage: cgImage!, size: NSSize.zero)
                }
            }
            catch let error as NSError {
                print("error reading eps: \(error.localizedDescription) in \(error.domain)")
            }
        default:
            if self.isImageFile {
                return NSImage(byReferencing: self.fileURL)
            }
        }
        return nil
    }
    
    init(url: Foundation.URL) {
        self.fileURL = url
        self.resourceValues = try! url.resourceValues(forKeys: resourceValueKeys)
    }
    
}
