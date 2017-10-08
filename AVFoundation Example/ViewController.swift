//
//  ViewController.swift
//  AVFoundation Example
//
//  Created by Nikhil Manapure on 19/05/17.
//  Copyright © 2017 Nikhil Manapure. All rights reserved.
//

import UIKit
import AVFoundation


var startTime = NSDate()
func TICK(){ startTime =  NSDate() }
func TOCK(){ print("TICK TO TOCK: \(startTime.timeIntervalSinceNow)\n") }

/*
 <key>NSCameraUsageDescription</key>
 <string>App will use camera</string>
 <key>NSPhotoLibraryUsageDescription</key>
 <string>App will save images</string>

Add to info.plist
*/


class ViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tapHereLabel: UILabel!
    
    lazy var session = AVCaptureSession()
    
    // Type is AVCaptureOutput as it is super class of both AVCaptureStillImageOutput `Deprecated`( for before iOS 10.0) and AVCapturePhotoOutput(iOS 10.0 or newer)
    var output: AVCaptureOutput?
    var input: AVCaptureDeviceInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        var didSucceed = false
        
        if let camera = ViewController.getDevice(position: .back) {
            do {
                input = try AVCaptureDeviceInput(device: camera)
                setSessionPreset(as: AVCaptureSessionPresetPhoto)
                if(session.canAddInput(input)) {
                    session.addInput(input)
                    
                    if #available(iOS 10.0, *) {
                        output = AVCapturePhotoOutput()
                    } else {
                        let stillImageOutput = AVCaptureStillImageOutput()
                        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                        output = stillImageOutput
                    }
                    
                    if(session.canAddOutput(output)) {
                        session.addOutput(output)
                    }
                    if let layer = AVCaptureVideoPreviewLayer(session: session) {
                        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        layer.connection.videoOrientation = .portrait
                        layer.frame = cameraPreview.bounds
                        cameraPreview.layer.addSublayer(layer)
                        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.captureImage))
                        tap.delegate = self
                        cameraPreview.addGestureRecognizer(tap)
                        session.startRunning()
                        didSucceed = true
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        if !didSucceed {
            // Show alert
        }
    }
    
    class func getDevice(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified) {
                for device in deviceDescoverySession.devices {
                    if device.position == position {
                        return device
                    }
                }
            }
        } else {
            if let devices = AVCaptureDevice.devices() {
                for device in devices {
                    if let device = device as? AVCaptureDevice {
                        if(device.position == position){
                            return device
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func setSessionPreset(as sessionPreset: String) {
        if session.canSetSessionPreset(sessionPreset) {
            session.sessionPreset = sessionPreset;
        } else if session.canSetSessionPreset(AVCaptureSessionPresetHigh) {
            session.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    
    func captureImage () {
        if !tapHereLabel.isHidden {
            tapHereLabel.isHidden = true
        }
        TICK()
        if #available(iOS 10.0, *) {
            print("Capturing in MORE than 10.0")
            let settings = AVCapturePhotoSettings()
            settings.isAutoStillImageStabilizationEnabled = true
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat: [String : Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: 160,
                kCVPixelBufferHeightKey as String: 160
            ]
            settings.previewPhotoFormat = previewFormat
            if let output = output as? AVCapturePhotoOutput {
                output.capturePhoto(with: settings, delegate: self)
                // This will call the delegate method once the photo(in form of data) is taken
            }
        } else {
            print("Capturing in LESS than 10.0")
            // This has a completion handler which gets the image data
            if let output = output as? AVCaptureStillImageOutput {
                if let videoConnection = output.connection(withMediaType: AVMediaTypeVideo) {
                    output.captureStillImageAsynchronously(from: videoConnection) {
                        (imageDataSampleBuffer, error) -> Void in
                        if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
                            self.processAndDisplayImage(fromData: imageData)
                        } else {
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func saveImageToLocal(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func processAndDisplayImage(fromData imageData: Data) {
        //  let dataProvider = CGDataProvider(data: dataImage as CFData)
        //  let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        //  let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        if let image = UIImage(data: imageData) {
            print(image.size)
            self.imageView.image = image
            self.saveImageToLocal(image: image)
        } else {
            // imageData was not valid
        }
        TOCK()
    }
}

extension ViewController : UIGestureRecognizerDelegate {
    // Nothing to be implemented
}

@available(iOS 10.0, *)
extension ViewController : AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
            return
        }
        
        if let photoBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer,
            let imageData =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  photoBuffer, previewPhotoSampleBuffer: previewBuffer) {
            processAndDisplayImage(fromData: imageData)
        } else {
            print("some error here")
        }
    }
    
}
