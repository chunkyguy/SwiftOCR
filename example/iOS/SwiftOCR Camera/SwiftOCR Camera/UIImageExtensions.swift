//
//  ImageTransforms.swift
//  UIImageTransformsDemo
//
//  Created by Rafal Bereski on 30.01.2016.
//  Copyright © 2016 Rafał Bereski. All rights reserved.
//  Additions by Sid on 5/8/16.
//

import UIKit
import GLKit

extension UIImage
{
    // Resizing without keeping aspect ratio of the original image
    func resize(size newSize: CGSize) -> UIImage {
        let ctx = createBitmapContext(width: Int(newSize.width), height: Int(newSize.height))
        CGContextDrawImage(ctx, CGRect(origin: CGPointZero, size: newSize), self.CGImage!)
        let resizedImage = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        return resizedImage
    }


    private func createBitmapContext(width width: Int, height: Int) -> CGContext {
        let image = self.CGImage!
        let bitsPerComponent = CGImageGetBitsPerComponent(image)
        let colorSpace = CGImageGetColorSpace(image)
        let bitmapInfo = CGImageGetBitmapInfo(image).rawValue
        let ctx = CGBitmapContextCreate(nil, width, height, bitsPerComponent, 0, colorSpace, bitmapInfo)
        return ctx!
    }


    // Resizing with keeping aspect ratio of the original image
    func resizeWithAspectFill(size newSize : CGSize) -> UIImage {
        let ctx = createBitmapContext(width: Int(newSize.width), height: Int(newSize.height))
        let originalAspectRatio = size.width/size.height
        let newAspectRatio = newSize.width/newSize.height

        let scaleFactor = originalAspectRatio < newAspectRatio ? newSize.width/size.width : newSize.height/size.height
        CGContextTranslateCTM(ctx, newSize.width/2, newSize.height/2)
        CGContextScaleCTM(ctx, scaleFactor, scaleFactor)

        let dstRect = CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height)
        CGContextDrawImage(ctx, dstRect, self.CGImage!)

        let resizedImage = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        return resizedImage
    }


    // Rotation

    func rotateImage(image: UIImage, angle: Double) -> UIImage {
        let angle = GLKMathDegreesToRadians(Float(angle))
        return image.rotate(CGFloat(angle))
    }

    func rotate(angle : CGFloat) -> UIImage {
        // New size after rotation multiplied by UIImage scale
        let newWidth: CGFloat = abs(size.width * cos(angle)) + abs(size.height * sin(angle)) * self.scale
        let newHeight: CGFloat = abs(size.width * sin(angle)) + abs(size.height * cos(angle)) * self.scale

        let ctx = createBitmapContext(width: Int(newWidth), height: Int(newHeight))

        // Setup transformation matrix
        CGContextTranslateCTM(ctx, newWidth/2, newHeight/2)
        CGContextRotateCTM(ctx, -angle)

        // Draw original image in the center of the new bitmap
        let dstRect = CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height)
        CGContextDrawImage(ctx, dstRect, self.CGImage!)

        let rotatedImage = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        return rotatedImage
    }
}


func * (l : CGSize, r: CGFloat) -> CGSize {
    return CGSize(width: l.width * r, height: l.height * r)
}

func imageCenterRect(image: UIImage, height: CGFloat) -> CGRect {
    let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: image.size.width, height: height))
    return CGRectOffset(frame, 0, image.size.height/2.0 - height/2.0)
}

extension UIImage {
    func crop(height: CGFloat) -> UIImage? {
//        return croppedImageWithSize(CGSize(width: size.width, height: height))
//        return croppedImageWithFrame(imageCenterRect(self, height: height))
        return croppedImageWithSize(CGSize(width: UIScreen.mainScreen().bounds.width, height: height))
    }
}

/**
 Crop utility
 http://stackoverflow.com/a/19465139/286094
 */
extension UIImage {
    func croppedImageWithSize(cropSize: CGSize) -> UIImage? {

        //calculate scale factor to go between cropframe and original image
        let SF = size.width / cropSize.width

        //find the centre x,y coordinates of image
        let centreX = size.width / 2
        let centreY = size.height / 2

        //calculate crop parameters
        let cropX = centreX - ((cropSize.width / 2) * SF)
        let cropY = centreY - ((cropSize.height / 2) * SF)

        let cropRect = CGRect(x: cropX, y: cropY, width: (cropSize.width * SF), height: (cropSize.height * SF))

        return croppedImageWithFrame(cropRect)
    }

    func croppedImageWithFrame(cropRect: CGRect) -> UIImage? {

        var rectTransform: CGAffineTransform
        switch (imageOrientation) {
        case UIImageOrientation.Left:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(M_PI_2)), 0, -size.height)
        case UIImageOrientation.Right:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-CGFloat(M_PI_2)), -size.width, 0)
        case UIImageOrientation.Down:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-CGFloat(M_PI)), -size.width, -size.height)
        default:
            rectTransform = CGAffineTransformIdentity
        }
        rectTransform = CGAffineTransformScale(rectTransform, scale, scale)

        guard let imageRef = CGImageCreateWithImageInRect(self.CGImage, CGRectApplyAffineTransform(cropRect, rectTransform)) else {
            return nil
        }

        let result = UIImage(CGImage: imageRef, scale: scale, orientation: imageOrientation)

        //Now want to scale down cropped image!
        //want to multiply frames by 2 to get retina resolution
        let scaledImgRect = CGRect(x: 0, y: 0, width: (cropRect.width * 2), height: (cropRect.height * 2))

        UIGraphicsBeginImageContextWithOptions(scaledImgRect.size, false, UIScreen.mainScreen().scale)
        
        result.drawInRect(scaledImgRect)
        
        let scaledNewImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledNewImage
    }
}