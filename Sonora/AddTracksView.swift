//
//  AddTracksView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/1/25.
//

import SwiftUI
import AVFoundation

struct AddTracksView: View {
    @Binding var isPresented: Bool
    @Binding var showPopup: String
    @State var selectedFiles: [URL]
    @State private var tracksToAdd: [(String?, String?, String?, UIImage?, Int?)] = []
    @State private var isFilePickerPresented = false
    
    var body: some View {
        NavigationView {
            GeometryReader { _ in
                VStack {
                    List {
                        Button(action: {
                            isFilePickerPresented = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Add Tracks")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        ForEach(Array(tracksToAdd.enumerated()), id: \.0) { index, element in
                            HStack {
                                if let artwork = element.3 {
                                    Image(uiImage: artwork)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .animation(nil)
                                }
                                else {
                                    Image(systemName: "music.note.list")
                                        .font(.subheadline)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.5))
                                        .animation(nil)
                                }
                                VStack(spacing: 0) {
                                    HStack {
                                        if let title = element.0 {
                                            Text(title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        else {
                                            Text(selectedFiles[index].deletingPathExtension().lastPathComponent)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        Spacer()
                                    }
                                    HStack {
                                        if let artist = element.1 {
                                            Text(artist)
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        else {
                                            Text("Unknown Artist")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        Spacer()
                                    }
                                }
                                Spacer()
                                Text("\(index+1)")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteFile)
                    }
                    .listStyle(PlainListStyle())
                }
                .padding(.top, 5)
                .navigationTitle("\(selectedFiles.count) Files Selected")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue),
                    trailing: Button("Save") {
                        if !selectedFiles.isEmpty {
                            let trackPaths = copyFilesToDocuments(sourceURLs: selectedFiles)
                            for i in 0..<trackPaths.count {
                                var trackArtist = "Unknown Artist"
                                var trackTitle = URL(fileURLWithPath: trackPaths[i]).deletingPathExtension().lastPathComponent
                                if let artwork = tracksToAdd[i].3 {
                                    let resizedArtwork = Utils.shared.resizeImage(image: artwork, newSize: CGSize(width: 600, height: 600))
                                    let resizedArtworkSmall = Utils.shared.resizeImage(image: artwork, newSize: CGSize(width: 100, height: 100))
                                    Utils.shared.copyLooseTrackImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, trackPath: trackPaths[i])
                                }
                                if let artist = tracksToAdd[i].1 { trackArtist = artist }
                                if let title = tracksToAdd[i].0 { trackTitle = title }
                                
                                let artworkPath = "Loose_Tracks/" + URL(fileURLWithPath: trackPaths[i]).deletingPathExtension().lastPathComponent + ".jpg"
                                let smallArtworkPath = "Loose_Tracks/" + URL(fileURLWithPath: trackPaths[i]).deletingPathExtension().lastPathComponent + "_small.jpg"
                                let track = Track(artist: trackArtist, title: trackTitle, artwork: artworkPath, smallArtwork: smallArtworkPath, path: trackPaths[i])
                                TrackManager.shared.addTrack(track, key: "Loose_Tracks")
                            }
                        }
                        showPopup = "Imported \(selectedFiles.count) track(s)"
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tracksToAdd.append(contentsOf: Utils.shared.fetchMetadata(from: selectedFiles))
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
    }
    
    private func deleteFile(at offsets: IndexSet) {
        selectedFiles.remove(atOffsets: offsets)
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.map { $0.startAccessingSecurityScopedResource() }
            selectedFiles.append(contentsOf: urls)
            tracksToAdd.append(contentsOf: Utils.shared.fetchMetadata(from: urls))
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    private func copyFilesToDocuments(sourceURLs: [URL]) -> [String] {
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
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try destinationURL.disableFileProtection()
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        selectedFiles.map { $0.stopAccessingSecurityScopedResource() }
        return filePaths
    }
}
