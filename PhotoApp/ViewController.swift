//
//  ViewController.swift
//  PhotoApp
//
//  Created by Stanislav Ageev on 26.07.2021.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pickButton: UIButton!
    
    @IBAction func onPickButtonTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true) {
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        picker.dismiss(animated: true)
        
        processImage(image: image)
//        self.imageView.image = image
    }
}

extension ViewController {
    func processImage(image: UIImage) {
        guard let model = try? VNCoreMLModel(for: StyleBlue().model) else { return }
        let mlRequest = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let res = request.results?.first as? VNPixelBufferObservation else { return }
            let ciImage = CIImage(cvPixelBuffer: res.pixelBuffer)
            let resultImage = UIImage(ciImage: ciImage)
            
            DispatchQueue.main.async {
                self.imageView.image = resultImage
            }
        }
        
        let cgImage = image.cgImage!
        
        let requestHandler =  VNImageRequestHandler(cgImage: cgImage)
        try? requestHandler.perform([mlRequest])
    }
}

