//
//  Utils.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/4/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import AudioToolbox

class Utils {
    static let shared = Utils()
    
    func copyImagesToDocuments(artwork: UIImage?, smallArtwork: UIImage?, directory: String) {
        guard artwork != nil else { return }
        guard smallArtwork != nil else { return }
        let image = artwork!.jpegData(compressionQuality: 1)!
        let smallImage = smallArtwork!.jpegData(compressionQuality: 1)!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(directory + "/artwork.jpg")
        let fileURLSmall = documentsURL.appendingPathComponent(directory + "/artwork_small.jpg")

        do {
            try image.write(to: fileURL)
            try smallImage.write(to: fileURLSmall)
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
    
    func copyLooseTrackImagesToDocuments(artwork: UIImage?, smallArtwork: UIImage?, trackPath: String) -> (first: String, last: String) {
        guard artwork != nil else { return (first: "", last: "") }
        guard smallArtwork != nil else { return (first: "", last: "") }
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
            return (first: "", last: "")
        }
    }
    
    func loadImageFromDocuments(filePath: String) -> UIImage? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filePath)
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
    
    func getSmallArtworkPath(from artworkPath: String) -> String {
        var result = artworkPath
        if let range = result.range(of: ".jpg") {
            result.insert(contentsOf: "_small", at: range.lowerBound)
        }
        return result
    }
    
    func convertTrackToAVPlayerItem(from track: Track) -> AVPlayerItem {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let trackURL = documentsDirectory.appendingPathComponent(track.path)
        return AVPlayerItem(url: trackURL)
    }
    
    func isAudioFile(url: URL) -> Bool {
        guard let fileType = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return fileType.conforms(to: .audio)
    }
    
    
    func isFLACFile(url: URL) -> Bool {
        let fileURL = URL(fileURLWithPath: url.path)
        if let fileType = UTType(filenameExtension: fileURL.pathExtension) {
            return fileType.conforms(to: .audio) && fileType.identifier == "org.xiph.flac"
        }
        return false
    }
    
    func isImageFile(url: URL) -> Bool {
        guard let fileType = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return fileType.conforms(to: .image)
    }
    
    func checkDocumentsForNewImports() -> (albums: [String : (tracks: [URL], artwork: UIImage?)], looseTracks: [URL]) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tracks = TrackManager.shared.getTracksDict()
        var looseTracks: [URL] = []
        var albums: [String : (tracks: [URL], artwork: UIImage?)] = [:]
        
        do {
            let documentsContents = try fileManager.contentsOfDirectory(at: documentsDirectory,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: [])
            
            for url in documentsContents {
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if isDirectory.boolValue {
                    var albumTracks: [URL] = []
                    if tracks[url.lastPathComponent] == nil {
                        url.startAccessingSecurityScopedResource()
                        let albumContents = try fileManager.contentsOfDirectory(at: url,
                                                                                includingPropertiesForKeys: nil,
                                                                                options: [])
                        
                        var artwork: UIImage? = nil
                        for subUrl in albumContents {
                            if isAudioFile(url: subUrl) {
                                albumTracks.append(subUrl)
                            }
                            else if isImageFile(url: subUrl) {
                                if let image = UIImage(contentsOfFile: subUrl.path) {
                                    if let currArtwork = artwork {
                                        let currArea = currArtwork.size.width * currArtwork.size.height
                                        let newArea = image.size.width * image.size.height
                                        if newArea > currArea {
                                            artwork = image
                                        }
                                    }
                                    else {
                                        artwork = image
                                    }
                                }
                            }
                        }
                        if !albumTracks.isEmpty {
                            albums[url.lastPathComponent] = (albumTracks, artwork)
                        }
                    }
                }
                else {
                    if isAudioFile(url: url) {
                        url.startAccessingSecurityScopedResource()
                        looseTracks.append(url)
                    }
                }
            }
        } catch {
            
        }
        
        return (albums, looseTracks)
    }
    
    func moveLooseTracksImportToDocuments(sourceURLs: [URL]) -> [String] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let looseTracksDirectory = documentsURL.appendingPathComponent("Loose_Tracks")
        var filePaths: [String] = []
        
        
        if !Utils.shared.directoryExists(at: looseTracksDirectory) {
            do {
                try fileManager.createDirectory(at: looseTracksDirectory, withIntermediateDirectories: true, attributes: nil)
                try looseTracksDirectory.disableFileProtection()
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
            }
        }
        
        for sourceURL in sourceURLs {
            var destinationURL = looseTracksDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            var count = 1
            while fileManager.fileExists(atPath: destinationURL.path) {
                if count > 1 {
                    let newDestinationURL = destinationURL.path.replacingOccurrences(
                        of: "\(sourceURL.deletingPathExtension().lastPathComponent)__\(count-1)",
                        with: "\(sourceURL.deletingPathExtension().lastPathComponent)__\(count)")
                    destinationURL = URL(fileURLWithPath: newDestinationURL)
                }
                else {
                    let newDestinationURL = destinationURL.path.replacingOccurrences(
                        of: "\(sourceURL.deletingPathExtension().lastPathComponent)",
                        with: "\(sourceURL.deletingPathExtension().lastPathComponent)__1")
                    destinationURL = URL(fileURLWithPath: newDestinationURL)
                }
                count+=1
            }
            
            var filePath = ""
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            if count > 1 {
                filePath = "Loose_Tracks/\(title)__\(count-1).\(ext)"
            }
            else {
                filePath = "Loose_Tracks/\(title).\(ext)"
            }
        
            do {
                try fileManager.moveItem(at: sourceURL, to: destinationURL)
                try destinationURL.disableFileProtection()
                filePaths.append(filePath)
            } catch {
                print("Unable to move file: \(error.localizedDescription)")
            }
        }
        sourceURLs.map { $0.stopAccessingSecurityScopedResource() }
        return filePaths
    }
    
    func moveAlbumImportToDocuments(sourceURLs: [URL], name: String) -> (first: [String], last: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var sanitizedAlbumName = name.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
        var filePaths: [String] = []

        if sanitizedAlbumName.isEmpty {
            sanitizedAlbumName = "Untitled"
        }
        
        var albumDirectory = documentsURL.appendingPathComponent(sanitizedAlbumName)
        if sanitizedAlbumName == name {
            do {
                try albumDirectory.disableFileProtection()
            } catch {
                print("Error disabling directory protection: \(error.localizedDescription)")
            }
            
            for sourceURL in sourceURLs {
                let filePath = sanitizedAlbumName + "/" + sourceURL.lastPathComponent
                
                do {
                    try sourceURL.disableFileProtection()
                    filePaths.append(filePath)
                } catch {
                    print("Error disabling file protection: \(error.localizedDescription)")
                }
            }
        }
        else {
            var count = 1
            while Utils.shared.directoryExists(at: albumDirectory) {
                if count > 1 {
                    let newDirectory = albumDirectory.path.replacingOccurrences(
                        of: "\(sanitizedAlbumName)__\(count-1)",
                        with: "\(sanitizedAlbumName)__\(count)")
                    albumDirectory = URL(fileURLWithPath: newDirectory)
                }
                else {
                    let newDirectory = albumDirectory.path.replacingOccurrences(
                        of: "\(sanitizedAlbumName)",
                        with: "\(sanitizedAlbumName)__1")
                    albumDirectory = URL(fileURLWithPath: newDirectory)
                }
                count+=1
            }
            
            do {
                try fileManager.createDirectory(at: albumDirectory, withIntermediateDirectories: true, attributes: nil)
                try albumDirectory.disableFileProtection()
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
            }
            
            for sourceURL in sourceURLs {
                let destinationURL = albumDirectory.appendingPathComponent(sourceURL.lastPathComponent)
                let filePath = count > 1 ?
                sanitizedAlbumName + "__\(count-1)/" + sourceURL.lastPathComponent :
                sanitizedAlbumName + "/" + sourceURL.lastPathComponent
                
                if fileManager.fileExists(atPath: destinationURL.path) {
                    continue
                }
                
                do {
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                    try destinationURL.disableFileProtection()
                    filePaths.append(filePath)
                } catch {
                    print("Unable to move file: \(error.localizedDescription)")
                }
            }
        }
        let result = (first: filePaths, last: albumDirectory.lastPathComponent)
        sourceURLs.map { $0.stopAccessingSecurityScopedResource() }
        return result
    }
    
    func handleNewImports(imports: (albums: [String : (tracks: [URL], artwork: UIImage?)], looseTracks: [URL])) {
        var looseTrackPaths: [String] = []
        var looseTrackMetadata: [(String?, String?, String?, UIImage?, Int?)] = []
        if !imports.looseTracks.isEmpty {
            looseTrackMetadata.append(contentsOf: Utils.shared.fetchMetadata(from: imports.looseTracks))
            looseTrackPaths = Utils.shared.moveLooseTracksImportToDocuments(sourceURLs: imports.looseTracks)
        }
        
        for i in 0..<looseTrackPaths.count {
            var trackArtist = "Unknown Artist"
            var trackTitle = URL(fileURLWithPath: looseTrackPaths[i]).deletingPathExtension().lastPathComponent
            if let artwork = looseTrackMetadata[i].3 {
                let resizedArtwork = Utils.shared.resizeImage(image: artwork, newSize: CGSize(width: 600, height: 600))
                let resizedArtworkSmall = Utils.shared.resizeImage(image: artwork, newSize: CGSize(width: 100, height: 100))
                Utils.shared.copyLooseTrackImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, trackPath: looseTrackPaths[i])
            }
            if let artist = looseTrackMetadata[i].1 { trackArtist = artist }
            if let title = looseTrackMetadata[i].0 { trackTitle = title }
            
            let artworkPath = "Loose_Tracks/" + URL(fileURLWithPath: looseTrackPaths[i]).deletingPathExtension().lastPathComponent + ".jpg"
            let smallArtworkPath = "Loose_Tracks/" + URL(fileURLWithPath: looseTrackPaths[i]).deletingPathExtension().lastPathComponent + "_small.jpg"
            let track = Track(artist: trackArtist, title: trackTitle, artwork: artworkPath, smallArtwork: smallArtworkPath, path: looseTrackPaths[i])
            TrackManager.shared.addTrack(track, key: "Loose_Tracks")
        }
        
        for (name, (tracks, artwork)) in imports.albums {
            var albumArtwork: UIImage? = artwork
            var albumName: String = name
            var albumArtist: String = "Unknown Artist"
            var trackTitles: [String?] = []
            var trackNumbers: [Int?] = []
            
            let metadata = Utils.shared.fetchMetadata(from: tracks)
            for (title, artist, album, artwork, trackNum) in metadata {
                if let artwork = artwork {
                    if albumArtwork == nil {
                        albumArtwork = artwork
                    }
                }
                if let album = album {
                    if albumName == name {
                        albumName = album
                    }
                }
                if let artist = artist {
                    if albumArtist == "Unknown Artist" {
                        albumArtist = artist
                    }
                }
                trackTitles.append(title)
                trackNumbers.append(trackNum)
            }
            let sortedIndices = trackNumbers.enumerated().sorted { curr, next in
                guard let num0 = curr.element, let num1 = next.element else {
                    return curr.element != nil
                }
                return num0 < num1
            }.map { $0.offset }
            trackNumbers = sortedIndices.map { trackNumbers[$0] }
            trackTitles = sortedIndices.map { trackTitles[$0] }
            
            let tuple = Utils.shared.moveAlbumImportToDocuments(sourceURLs: tracks, name: name)
            var filePaths = tuple.first
            filePaths = sortedIndices.map { filePaths[$0] }
            let directory = tuple.last
            let artworkPath = directory + "/artwork.jpg"
            let smallArtworkPath = directory + "/artwork_small.jpg"
            let resizedArtwork = Utils.shared.resizeImage(image: albumArtwork, newSize: CGSize(width: 600, height: 600))
            let resizedArtworkSmall = Utils.shared.resizeImage(image: albumArtwork, newSize: CGSize(width: 100, height: 100))
            Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: directory)
            var tracklist: [Track] = []
            for i in 0..<filePaths.count {
                if let title = trackTitles[i] {
                    tracklist.append(Track(artist: albumArtist, title: title, artwork: artworkPath, smallArtwork: smallArtworkPath, path: filePaths[i]))
                }
                else {
                    tracklist.append(Track(artist: albumArtist, artwork: artworkPath, smallArtwork: smallArtworkPath, path: filePaths[i]))
                }
            }
            
            let newAlbum = Album(name: albumName,
                                 artist: albumArtist,
                                 artwork: artworkPath,
                                 smallArtwork: smallArtworkPath,
                                 directory: directory)
            
            if directory != name {
                Utils.shared.deleteRemainingImportDirectory(path: name)
            }
            TrackManager.shared.addTracklist(tracklist, key: directory)
            AlbumManager.shared.saveAlbum(newAlbum)
        }
    }
    
    func deleteRemainingImportDirectory(path: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = documentsDirectory.appendingPathComponent(path)
        if fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.removeItem(at: directory)
            } catch {
                print("Failed to delete directory: \(path)")
            }
        }
    }
    
    func getFLACMetadata(url: URL) -> (String?, String?, String?, UIImage?, Int?) {
        let fileURL = URL(fileURLWithPath: url.path)
        var audioFile: AudioFileID?
        
        let status = AudioFileOpenURL(fileURL as CFURL, .readPermission, 0, &audioFile)
        
        guard status == noErr, let audioFile = audioFile else {
            print("Error opening file: \(status)")
            return (nil, nil, nil, nil, nil)
        }
        
        defer {
            AudioFileClose(audioFile)
        }
        
        var dictionarySize: UInt32 = 0
        var isWritable: UInt32 = 0
        let dictionaryStatus = AudioFileGetPropertyInfo(audioFile, kAudioFilePropertyInfoDictionary, &dictionarySize, &isWritable)
        
        guard dictionaryStatus == noErr else {
            print("Error retrieving metadata dictionary info")
            return (nil, nil, nil, nil, nil)
        }
        
        var dictionary: CFDictionary?
        let metadataStatus = AudioFileGetProperty(audioFile, kAudioFilePropertyInfoDictionary, &dictionarySize, &dictionary)
        
        guard metadataStatus == noErr, let metadataDict = dictionary as? [String: Any] else {
            print("Error retrieving metadata dictionary")
            return (nil, nil, nil, nil, nil)
        }
        
        let title = metadataDict[kAFInfoDictionary_Title as String] as? String
        let artist = metadataDict[kAFInfoDictionary_Artist as String] as? String
        let album = metadataDict[kAFInfoDictionary_Album as String] as? String
        let trackNumberString = metadataDict[kAFInfoDictionary_TrackNumber as String] as? String
        var trackNumber: Int?
        if let num = trackNumberString {
            trackNumber = Int(num)
        }
        
        var artwork: UIImage? = nil
        var artworkSize: UInt32 = 0
        if AudioFileGetPropertyInfo(audioFile, kAudioFilePropertyAlbumArtwork, &artworkSize, nil) == noErr {
            var artworkData = Data(count: Int(artworkSize))
            let result = artworkData.withUnsafeMutableBytes { buffer in
                guard let baseAddress = buffer.baseAddress else { return kAudioFileUnspecifiedError }
                return AudioFileGetProperty(audioFile, kAudioFilePropertyAlbumArtwork, &artworkSize, baseAddress)
            }
            if result == noErr {
                artwork = UIImage(data: artworkData)
            }
        }
        return (title, artist, album, artwork, trackNumber)
    }

    func fetchMetadata(from urls: [URL]) -> [(String?, String?, String?, UIImage?, Int?)] {
        var results: [(String?, String?, String?, UIImage?, Int?)] = []
        
        for url in urls {
            if isFLACFile(url: url) {
                let result = getFLACMetadata(url: url)
                results.append(result)
            }
            else {
                let asset = AVAsset(url: url)
                let metadata = asset.metadata
                var title: String?
                var artist: String?
                var album: String?
                var artwork: UIImage?
                var trackNum: Int?
                
                for item in metadata {
                    switch item.commonKey {
                    case .commonKeyTitle:
                        title = item.stringValue
                    case .commonKeyArtist:
                        artist = item.stringValue
                    case .commonKeyAlbumName:
                        album = item.stringValue
                    case .commonKeyArtwork:
                        if let data = item.dataValue {
                            artwork = UIImage(data: data)
                        }
                    default:
                        break
                    }
                }
                if let item = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .id3MetadataTrackNumber).first {
                    if let num = item.stringValue {
                        trackNum = Int(num)
                    }
                }
                results.append((title, artist, album, artwork, trackNum))
            }
        }
        return results
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

extension URL {
    var parentDirectory: URL? { try? resourceValues(forKeys: [.parentDirectoryURLKey]).parentDirectory }
    var fileProtection: URLFileProtection? { try? resourceValues(forKeys: [.fileProtectionKey]).fileProtection }
    func disableFileProtection() throws { try (self as NSURL).setResourceValue(URLFileProtection.none, forKey: .fileProtectionKey) }
}
