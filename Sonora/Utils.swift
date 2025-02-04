//
//  Utils.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/4/25.
//

import SwiftUI

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
}
