//
//  ViewController.swift
//  CoreMLImageRecognition
//  Simple single view page to get the image and use CoreML to recognize object
//  Created by yoovraj shinde on 2018/04/21.
//  Copyright © 2018 ___YOOVRAJSHINDE___. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController , UINavigationControllerDelegate {
    
    // model instance for object recognition model
    var model:Inceptionv3!
    
    // UI components
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var libraryButton: UIButton!
    
    // image which is under analysis
    @IBOutlet var imageView: UIImageView!
    
    // prediction results displayed in this label
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "First Object Recognition using CoreML"
        
        // plug in the actions for buttons
        cameraButton.addTarget(self, action: #selector(camera), for: .touchDown)
        libraryButton.addTarget(self, action: #selector(library), for: .touchDown)
        
        // initialize the model
        model = Inceptionv3()
    }

    // called when camera button is clicked
    @objc func camera() {
        print("Camera selected")
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    // called when user selects photo from library
    @objc func library() {
        print("Library selected")
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

}

extension ViewController : UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // processing the captured image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        label.text = "Analyzing Image ..."
        
        // get the image
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        // convert it into pixelbuffer of 299x299
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey:kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer : CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int((newImage?.size.width)!),
                                         Int((newImage?.size.height)!),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int((newImage?.size.width)!),
                                height: Int((newImage?.size.height)!),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.translateBy(x: 0, y: (newImage?.size.height)!)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage?.draw(in: CGRect(x: 0, y: 0, width: (newImage?.size.width)!, height: (newImage?.size.height)!))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        imageView.image = newImage
        
        // pass the image to model for prediction
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        print(prediction.classLabel)
        
        // this print will print almost 1000 detected objects with each probailities
        // you will run out of display to show all results haha
        //print(prediction.classLabelProbs)
        label.text = "I think this is \(prediction.classLabel)"
    }
}
