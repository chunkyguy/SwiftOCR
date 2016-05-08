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
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        startProcessing()
    }

}

private extension ResultViewController {
    // MARK: Image Processing

    private func startProcessing() {
        if let output = stillImageOutput {
            processStreamCapture(output)
        } else if let image = UIImage(named: "lines") {
            processImage(image)
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

            self?.processImage(image)
        }
    }

    private func processImage(image: UIImage) {
        updateStatus("Processing 1/3 ...", image: image)

        guard let cropImg = image.crop(CGRectGetHeight(clippedRect)) else {
            return
        }

        updateStatus("Processing 2/3 ...", image: cropImg)

        let ocrInstance = SwiftOCR()
        ocrInstance.image = cropImg
        ocrInstance.recognize() { [weak self] recognizedString in
            dispatch_async(dispatch_get_main_queue(), {
                if recognizedString.characters.isEmpty {
                    self?.updateStatus("Can't read!", image: cropImg)
                } else {
                    self?.updateStatus(recognizedString, image: cropImg)
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
