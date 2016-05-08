//
//  ViewController.swift
//  SwiftOCR Camera
//
//  Created by Nicolas Camenisch on 04.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import UIKit
import SwiftOCR
import AVFoundation

private let ShowResultsSegueId = "ShowResults"

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var slider: UISlider! {
        didSet {
            slider.value = 1.0
        }
    }
    
    private var stillImageOutput: AVCaptureStillImageOutput?
    private var captureSession: AVCaptureSession?
    private var device: AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [weak self] in
            self?.beginSession()
        })
        
    }
    
    // MARK: AVFoundation
    
    func beginSession() {

        device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

        guard let device = device else {
            return
        }

        captureSession = AVCaptureSession()

        guard let captureSession = captureSession else {
            return
        }


        stillImageOutput = AVCaptureStillImageOutput()

        guard let stillImageOutput = stillImageOutput else {
            return
        }

        stillImageOutput.outputSettings = [
            AVVideoCodecKey: AVVideoCodecJPEG
        ]

//        if UIDevice.currentDevice().userInterfaceIdiom == .Phone && max(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height) < 568.0 {
//            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
//        } else {
//            captureSession.sessionPreset = AVCaptureSessionPreset1280x720
//        }

        captureSession.addOutput(stillImageOutput)
        let cameraViewSize = cameraView.frame.size

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { _ in
            
            do{
                captureSession.addInput(try AVCaptureDeviceInput(device: device))
            } catch {
                print("AVCaptureDeviceInput Error")
            }
            
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame.size = cameraViewSize
            previewLayer?.frame.origin = CGPoint.zero
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            do {
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = CGPointMake(0.5, 0.5)
                device.focusMode = .ContinuousAutoFocus
                
                device.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            //Set initial Zoom scale
            
            do {
                let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
                try device.lockForConfiguration()
                
                let zoomScale: CGFloat = 1.0
                
                if zoomScale <= device.activeFormat.videoMaxZoomFactor {
                    device.videoZoomFactor = zoomScale
                }
                
                device.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                self?.cameraView.layer.addSublayer(previewLayer)
                captureSession.startRunning()
            })
        })
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let segueIdentifier = segue.identifier where segueIdentifier == ShowResultsSegueId else {
            assertionFailure("Non supported segue \(segue.identifier)!")
            return
        }

        guard let navigationController = segue.destinationViewController as? UINavigationController, resultViewController = navigationController.topViewController as? ResultViewController else {
            assertionFailure("Destination is not ResultsViewController")
            return
        }

        resultViewController.clippedRect = viewFinder.frame
        resultViewController.stillImageOutput = stillImageOutput
    }

    @IBAction func sliderValueDidChange(sender: UISlider) {
        guard let device = device else {
            return
        }

        do {
            try device.lockForConfiguration()
            var zoomScale = CGFloat(slider.value * 10.0)
            
            if zoomScale < 1 {
                zoomScale = 1
            } else if zoomScale > device.activeFormat.videoMaxZoomFactor {
                zoomScale = device.activeFormat.videoMaxZoomFactor
            }
            
            device.videoZoomFactor = zoomScale
            device.unlockForConfiguration()
            
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
    }
    
    
}

