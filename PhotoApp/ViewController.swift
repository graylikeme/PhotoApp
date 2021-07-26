//
//  ViewController.swift
//  PhotoApp
//
//  Created by Stanislav Ageev on 26.07.2021.
//

import UIKit
import CoreML
import Vision
import Alamofire

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

struct HTTPBinResponse: Decodable { let id: String }

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        picker.dismiss(animated: true)
        
        processImage(image: image)
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
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.imageView.image = resultImage
                
//                let resizedImage = self.resizedImage(image: image, for: CGSize(width: 100, height: 100))!
                
                let headers: HTTPHeaders = [
                    "Authorization": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpb3MiLCJpYXQiOjE1MTYyMzkwMjJ9.NjEtvnTmcL-4fhKMhkOoTXIYncKdI9U4-erZ-h7YHW4"
                ]
                
                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(image.jpegData(compressionQuality: 0.4)!, withName: "image", fileName: "image.jpeg")
                }, to: "https://us-central1-aivision-app.cloudfunctions.net/talkingheadsapi/api/v0/avatars", headers: headers)
                .responseDecodable(of: HTTPBinResponse.self) { response in
                    debugPrint(response)
                }
            }
        }
        
        let cgImage = image.cgImage!
        
        let requestHandler =  VNImageRequestHandler(cgImage: cgImage)
        try? requestHandler.perform([mlRequest])
    }
    
    func resizedImage(image: UIImage, for size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
}

