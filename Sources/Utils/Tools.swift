import Foundation
import UIKit

extension CGImage {
    func newBitmapRGBA8Context() -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return CGContext(
            data: nil,
            width: self.width,
            height: self.height,
            bitsPerComponent: 8,
            bytesPerRow: self.width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    func newBitmapGrayContext() -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        return CGContext(
            data: nil,
            width: self.width,
            height: self.height,
            bitsPerComponent: 8,
            bytesPerRow: self.width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
    }
}

public extension UIImage {
    func crop(toRect rect: CGRect) -> UIImage? {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale

        guard let cgimage = self.cgImage else {
            return nil
        }
        guard let cropped = cgimage.cropping(to: rect) else {
            return nil
        }
        return UIImage(
            cgImage: cropped,
            scale: self.scale,
            orientation: self.imageOrientation
        )
    }
    
    func scale(to scale: Double) -> UIImage {
        let size = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        return self.scale(toRect: size)
    }
    
    func scale(toRect size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaled!
    }
    
    func convertToBitmapRGBA8() -> Data? {
        guard let imageRef = self.cgImage else {
            return nil
        }
        // Create a bitmap context to draw the uiimage into
        guard let context = imageRef.newBitmapRGBA8Context() else {
            return nil
        }
        let width = imageRef.width
        let height = imageRef.height
        // Draw image into the context to get the raw image data
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let bitmapData = context.data else {
            NSLog("Error getting bitmap pixel data\n")
            return nil
        }
        return Data(bytes: bitmapData, count: context.bytesPerRow * height)
    }

    func convertToBitmapGray() -> Data? {
        guard let imageRef = self.cgImage else {
            return nil
        }

        // Create a bitmap context to draw the uiimage into
        guard let context = imageRef.newBitmapGrayContext() else {
            return nil
        }

        let rect = CGRect(x: 0, y: 0, width: imageRef.width, height: imageRef.height)
        context.draw(imageRef, in: rect)
        guard let bitmapData = context.data else {
            NSLog("Error getting bitmap pixel data\n")
            return nil
        }
        return Data(bytes: bitmapData, count: context.bytesPerRow * imageRef.height)
    }
}
