//
//  ViewController.swift
//  FilterTask
//
//  Created by Blintsov Sergey on 08/07/2019.
//  Copyright © 2019 Sergey Blintsov. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var cameraView: UIView!
    let filtersViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "FiltersViewController") as UIViewController
    var captureSession: AVCaptureSession!
    var imageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var cameraPosition = cameraPositions.back
    
    enum cameraPositions {
        case front
        case back
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initCaptureSession()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    
    
    @IBAction func takePhotoButtonPressed(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        imageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func galeryButtonPressed(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func flipCameraButtonPressed(_ sender: UIButton) {
        captureSession.stopRunning()
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        do {
            switch cameraPosition {
                case .front:
                    try captureSession.addInput(AVCaptureDeviceInput(device: getDevice(position: .back)!))
                    cameraPosition = .back
                case .back:
                    try captureSession.addInput(AVCaptureDeviceInput(device: getDevice(position: .front)!))
                    cameraPosition = .front
            }
        } catch let error  {
            print("Can't init camera:  \(error.localizedDescription)")
        }
        captureSession.startRunning()
    }
    
    
    
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for de in devices.devices {
            let deviceConverted = de
            if(deviceConverted.position == position){
                return deviceConverted
            }
        }
        return nil
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        ImageModel.imageData = selectedImage.jpegData(compressionQuality: 1.0)
        dismiss(animated: true, completion: {
            self.present(self.filtersViewController, animated: true, completion: nil)
        })
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        ImageModel.imageData = imageData
        
        self.present(filtersViewController, animated: true, completion: nil)
    }
    
    func initCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let device = getDevice(position: .back) else {return}
        
        do {
            let imageInput = try AVCaptureDeviceInput(device: device)
            imageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(imageInput) && captureSession.canAddOutput(imageOutput) {
                captureSession.addInput(imageInput)
                captureSession.addOutput(imageOutput)
                setupLivePreview()
            }
        } catch let error  {
            print("Can't init camera:  \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.cameraView.bounds
            }
        }
    }
}
