//
//  UIImage+Pixel.swift
//  BouncyImage
//
//  Created by Shane Whitehead on 18/1/2022.
//

import Foundation
import Cocoa
import Cadmus

// Take the ambiguity out of the return result - is it y/x or x/y
struct Pixel {
    let point: CGPoint
    let color: NSColor
}

extension Pixel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(point.x)
        hasher.combine(point.y)
        hasher.combine(color)
    }

    static func == (lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.point == rhs.point
        && lhs.color == rhs.color
    }
}

extension NSImage {
    
    var cgImage: CGImage? {
//        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
//            let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    func pixels() -> [Pixel] {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        var pixels = [Pixel]()
        
        guard let cgImage = self.cgImage else { return pixels }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        
        for yPos in 0..<height {
            for xPos in 0..<width {
                let distanceFromBottom = height - yPos
                if let color = bitmap.colorAt(x: xPos, y: distanceFromBottom) {
                    pixels.append(Pixel(point: CGPoint(x: xPos, y: yPos), color: color))
                } else {
                    pixels.append(Pixel(point: CGPoint(x: xPos, y: yPos), color: NSColor.clear))
                }
            }
        }
        
        return pixels
    }
    
    func pixelated(size: CGFloat) -> NSImage? {
        guard let cgImage = cgImage else { return nil }
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(size, forKey: kCIInputScaleKey)

        guard let outputImage = filter.outputImage else { return nil }
        
        let outputImageRect = NSRectFromCGRect(outputImage.extent)
        let filteredImage = NSImage(size: outputImageRect.size)
        filteredImage.lockFocus()
        outputImage.draw(at: NSZeroPoint, from: outputImageRect, operation: .copy, fraction: 1.0)
        filteredImage.unlockFocus()
        
        return filteredImage
    }
    
    func subImage(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSImage? {
        return subImage(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    func subImage(origin: CGPoint, size: CGSize) -> NSImage? {
        return subImage(in: CGRect(origin: origin, size: size))
    }

//    func subImage(_ rect: CGRect) -> NSImage? {
//        guard let cgImage = cgImage else { return nil }
//        guard let subImage = cgImage.cropping(to: rect) else { return nil }
//        let cropSize = CGSize(width: cgImage.width, height: cgImage.height)
//        log(debug: "crop \(rect); cropped \(cropSize); \(scale)")
//        return NSImage(cgImage: subImage, size: cropSize)
//    }
    
    func subImage(in bounds: CGRect) -> NSImage {
        let result = NSImage(size: bounds.size)
        result.lockFocus()
        let destRect = CGRect(origin: .zero, size: bounds.size)
        draw(in: destRect, from: bounds, operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
    }
}
