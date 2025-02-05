//
//  Utils.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/4/25.
//

import SwiftUI
import AVFoundation

class Utils {
    static let shared = Utils()
    
    func copyImageToDocuments(artwork: UIImage?, directory: String) -> String? {
        guard artwork != nil else { return nil }
        let image = artwork!.jpegData(compressionQuality: 1)!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(directory + "/artwork.jpg")
        let filePath = directory + "/artwork.jpg"

        do {
            try image.write(to: fileURL)
            return filePath
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func copyTrackImageToDocuments(artwork: UIImage?, trackPath: String) -> String? {
        guard artwork != nil else { return nil }
        let image = artwork!.jpegData(compressionQuality: 1)!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let trackURL = documentsURL.appendingPathComponent(trackPath)
        let fileURL = documentsURL.appendingPathComponent("Loose_Tracks/" + trackURL.deletingPathExtension().lastPathComponent + ".jpg")
        let filePath = "Loose_Tracks/" + fileURL.lastPathComponent

        do {
            try image.write(to: fileURL)
            return filePath
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadImageFromDocuments(filePath: String?) -> UIImage? {
        guard filePath != nil else { return nil }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filePath!)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func resizeImage(image: UIImage?) -> UIImage? {
        guard image != nil else { return nil }
        let size = image!.size
        let widthRatio  = 600 / size.width
        let heightRatio = 600 / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image!.scale)
        image!.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func getTrackDuration(from path: String) -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let trackURL = documentsDirectory.appendingPathComponent(path)
        
        let asset = AVURLAsset(url: trackURL)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        if durationInSeconds.isFinite {
            let minutes = Int(durationInSeconds) / 60
            let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
            let stringSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "\(minutes):\(stringSeconds)"
        }
        else {
            return ""
        }
    }
    
    func directoryExists(at path: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var selectedImage: UIImage?

        init(selectedImage: Binding<UIImage?>) {
            _selectedImage = selectedImage
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            selectedImage = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
