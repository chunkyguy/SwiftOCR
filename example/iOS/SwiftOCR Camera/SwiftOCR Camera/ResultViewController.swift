//
//  ResultViewController.swift
//  SwiftOCR Camera
//
//  Created by Sid on 5/8/16.
//  Copyright © 2016 Sidharth Juyal. All rights reserved.
//

import UIKit
import SwiftOCR
import AVFoundation
import CoreImage
import GLKit

class ResultViewController: UIViewController {

    let ocrInstance = SwiftOCR()
    var stillImageOutput: AVCaptureStillImageOutput?
    var clippedRect: CGRect = CGRect.zero

    @IBOutlet weak var label: UILabel! {
        didSet {
            label.text = "Processing ..."
        }
    }
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.image = nil
        }
    }

    @IBOutlet weak var originalImageView: UIImageView!


    @IBAction func onDoneTap() {
        dismiss()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        startProcessing()
    }

    private func dismiss() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

private extension ResultViewController {
    // MARK: Image Processing

    private func startProcessing() {
        if let output = stillImageOutput {
            processStreamCapture(output)
        } else if let image = UIImage(named: "placeholder") {
            processImage(image, crop: false)
        } else {
            updateStatus("No image found")
        }
    }

    private func processStreamCapture(stillImageOutput: AVCaptureStillImageOutput) {
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { [weak self] (buffer:CMSampleBuffer!, error:NSError!) -> Void in

            guard let buffer = buffer else {
                self?.updateStatus("No data captures")
                return
            }

            guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), image = UIImage(data: imageData) else {
                self?.updateStatus("Unable to capture image")
                return
            }

            self?.processImage(image, crop: true)
        }
    }

    private func processImage(image: UIImage, crop: Bool) {
        updateStatus("Processing 1/3 ...", image: image)

        var cropImg = image
        if crop {
            if let c = image.crop(CGRectGetHeight(clippedRect)) {
                cropImg = c
            }
        }

        updateStatus("Processing 2/3 ...", image: cropImg)

        ocrInstance.image = cropImg
        guard let processedImg = ocrInstance.preprocessImageForOCR(nil) else {
            return
        }

        updateStatus("Processing 3/3 ...", image: processedImg)

        let alert = UIAlertController(title: "Good enough?", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { [weak self] _ in
            self?.recognizeImage()
            })
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { [weak self] _ in
            self?.dismiss()
            })
        )
        presentViewController(alert, animated: true, completion: nil)
    }

    private func recognizeImage() {
        ocrInstance.recognize() { [weak self] recognizedString in
            dispatch_async(dispatch_get_main_queue(), {
                if recognizedString.characters.isEmpty {
                    self?.updateStatus("Can't read!", image: self?.ocrInstance.image)
                } else {
                    self?.updateStatus(recognizedString, image: self?.ocrInstance.image)
                }
            })
        }
    }

    private func updateStatus(status: String, image: UIImage? = nil) {
        label.text = status
        if let image = image {
            imageView.image = image
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
    }
}
