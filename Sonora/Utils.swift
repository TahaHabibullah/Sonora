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
    
    func copyImagesToDocuments(artwork: UIImage?, smallArtwork: UIImage?, directory: String) -> (first: String?, last: String?) {
        guard artwork != nil else { return (first: nil, last: nil) }
        guard smallArtwork != nil else { return (first: nil, last: nil) }
        let image = artwork!.jpegData(compressionQuality: 1)!
        let smallImage = smallArtwork!.jpegData(compressionQuality: 1)!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(directory + "/artwork.jpg")
        let fileURLSmall = documentsURL.appendingPathComponent(directory + "/artwork_small.jpg")
        let filePath = directory + "/artwork.jpg"
        let filePathSmall = directory + "/artwork_small.jpg"

        do {
            try image.write(to: fileURL)
            try smallImage.write(to: fileURLSmall)
            let result = (first: filePath, last: filePathSmall)
            return result
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return (first: nil, last: nil)
        }
    }
    
    func copyLooseTrackImagesToDocuments(artwork: UIImage?, smallArtwork: UIImage?, trackPath: String) -> (first: String?, last: String?) {
        guard artwork != nil else { return (first: nil, last: nil) }
        guard smallArtwork != nil else { return (first: nil, last: nil) }
        let image = artwork!.jpegData(compressionQuality: 1)!
        let smallImage = smallArtwork!.jpegData(compressionQuality: 1)!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let trackURL = documentsURL.appendingPathComponent(trackPath)
        let fileURL = documentsURL.appendingPathComponent("Loose_Tracks/" + trackURL.deletingPathExtension().lastPathComponent + ".jpg")
        let fileURLSmall = documentsURL.appendingPathComponent("Loose_Tracks/" + trackURL.deletingPathExtension().lastPathComponent + "_small.jpg")
        let filePath = "Loose_Tracks/" + fileURL.lastPathComponent
        let filePathSmall = "Loose_Tracks/" + fileURL.deletingPathExtension().lastPathComponent + "_small.jpg"

        do {
            try image.write(to: fileURL)
            try smallImage.write(to: fileURLSmall)
            let result = (first: filePath, last: filePathSmall)
            return result
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return (first: nil, last: nil)
        }
    }
    
    func loadImageFromDocuments(filePath: String?) -> UIImage? {
        guard filePath != nil else { return nil }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filePath!)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func resizeImage(image: UIImage?, newSize: CGSize) -> UIImage? {
        guard image != nil else { return nil }
        let size = image!.size
        let widthRatio  = newSize.width / size.width
        let heightRatio = newSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        if scaleFactor >= 1 { return image }
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
    
    func getPlaylistDuration(from tracklist: [String]) -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var totalSeconds: Double = 0
        
        for trackPath in tracklist {
            let trackURL = documentsDirectory.appendingPathComponent(trackPath)
            let asset = AVURLAsset(url: trackURL)
            let duration = asset.duration
            let durationInSeconds = CMTimeGetSeconds(duration)
            if durationInSeconds.isFinite {
                totalSeconds += durationInSeconds
            }
        }
        
        let minutes = Int(totalSeconds) / 60
        let hours = minutes / 60
        return "\(hours)h \(minutes % 60)m"
    }
    
    func directoryExists(at path: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func getSmallArtworkPath(from artworkPath: String?) -> String? {
        guard artworkPath != nil else { return nil }
        var result = artworkPath!
        if let range = result.range(of: ".jpg") {
            result.insert(contentsOf: "_small", at: range.lowerBound)
        }
        return result
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

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private let cache = NSCache<NSString, UIImage>()
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}

class CacheImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage(from path: String) {
        DispatchQueue.global(qos: .background).async {
            if let cachedImage = ImageCache.shared.getImage(forKey: path) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }
            
            if let cachedImage = Utils.shared.loadImageFromDocuments(filePath: path) {
                ImageCache.shared.setImage(cachedImage, forKey: path)
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }
            
            print("Image not found at: \(path)")
        }
    }
}

struct CachedImageView: View {
    let path: String
    @StateObject private var loader = CacheImageLoader()
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "music.note.list")
                    .font(.subheadline)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.5))
                    .onAppear {
                        loader.loadImage(from: path)
                    }
            }
        }
    }
}

struct ImageDocumentPicker: UIViewControllerRepresentable {
    @Binding var imageURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image, UTType.png, UTType.jpeg])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ImageDocumentPicker

        init(_ parent: ImageDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.imageURL = urls.first
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.imageURL = nil
        }
    }
}
