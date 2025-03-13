//
//  AddAlbumView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/16/25.
//

import SwiftUI
import AVFoundation

struct AddAlbumView: View {
    @Binding var isPresented: Bool
    @Binding var showPopup: String
    @State var selectedFiles: [URL] = []
    @State private var albumName: String = ""
    @State private var artistName: String = ""
    @State private var albumArtwork: UIImage? = nil
    @State private var selectedTitles: [String?] = []
    @State private var selectedTrackNums: [Int?] = []
    @State private var isFilePickerAudioPresented = false
    @State private var isFilePickerImagesPresented = false
    @State private var isImagePickerPresented = false
    @State private var showImportOptions = false

    var body: some View {
        NavigationView {
            GeometryReader { _ in
                ScrollView {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showImportOptions = true
                    }) {
                        ZStack {
                            if let albumArtwork = albumArtwork {
                                Image(uiImage: albumArtwork)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                            }
                            else {
                                Image(systemName: "music.note.list")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(Color.gray.opacity(0.5))
                            }
                            
                            VStack {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.subheadline)
                                        .foregroundColor(Color.black.opacity(0.5))
                                }
                                .frame(width: 40, height: 40)
                                .background(.gray)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.5), radius: 5)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 10)
                    }
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Album Name")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            TextField("", text: $albumName)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.gray),
                                    alignment: .bottom
                                )
                                .autocorrectionDisabled(true)
                        }
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Artist(s)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            TextField("", text: $artistName)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.gray),
                                    alignment: .bottom
                                )
                                .autocorrectionDisabled(true)
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding(.top, 10)

                    List {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isFilePickerAudioPresented = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Add Tracks")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        ForEach(Array(selectedFiles.enumerated()), id: \.element) { index, element in
                            HStack {
                                if index < selectedTitles.count {
                                    if let title = selectedTitles[index] {
                                        Text(title)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    else {
                                        Text(element.deletingPathExtension().lastPathComponent)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                                else {
                                    Text(element.deletingPathExtension().lastPathComponent)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Spacer()
                                if index < selectedTrackNums.count {
                                    Text("\(selectedTrackNums[index] ?? index+1)")
                                        .foregroundColor(.gray)
                                }
                                else {
                                    Text("\(index+1)")
                                        .foregroundColor(.gray)
                                }
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                            }
                            .padding([.leading, .trailing])
                            .listRowInsets(EdgeInsets())
                        }
                        .onDelete(perform: deleteFile)
                        .onMove(perform: moveFile)
                    }
                    .listStyle(PlainListStyle())
                    .scrollDisabled(true)
                    .frame(height: CGFloat(100 + selectedFiles.count * 45))
                }
                .confirmationDialog("", isPresented: $showImportOptions, titleVisibility: .hidden) {
                    Button("Import From Photo Library") {
                        isImagePickerPresented = true
                    }
                    Button("Import From Files") {
                        isFilePickerImagesPresented = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .navigationTitle("New Album")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue),
                    trailing: Button("Save") {
                        let tuple = copyFilesToDocuments(sourceURLs: selectedFiles, name: albumName)
                        let filePaths = tuple.first
                        let directory = tuple.last
                        let artworkPath = directory + "/artwork.jpg"
                        let smallArtworkPath = directory + "/artwork_small.jpg"
                        let resizedArtwork = Utils.shared.resizeImage(image: albumArtwork, newSize: CGSize(width: 600, height: 600))
                        let resizedArtworkSmall = Utils.shared.resizeImage(image: albumArtwork, newSize: CGSize(width: 100, height: 100))
                        Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: directory)
                        var tracklist: [Track] = []
                        for i in 0..<filePaths.count {
                            if let title = selectedTitles[i] {
                                tracklist.append(Track(artist: artistName,
                                                       title: title,
                                                       artwork: artworkPath,
                                                       smallArtwork: smallArtworkPath,
                                                       path: filePaths[i]))
                            }
                            else {
                                tracklist.append(Track(artist: artistName,
                                                       artwork: artworkPath,
                                                       smallArtwork: smallArtworkPath,
                                                       path: filePaths[i]))
                            }
                        }
                        
                        let newAlbum = Album(name: albumName,
                                             artist: artistName,
                                             artwork: artworkPath,
                                             smallArtwork: smallArtworkPath,
                                             directory: directory)
                        
                        TrackManager.shared.addTracklist(tracklist, key: directory)
                        AlbumManager.shared.saveAlbum(newAlbum)
                        showPopup = "Created album"
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .fileImporter(
                isPresented: $isFilePickerImagesPresented,
                allowedContentTypes: [.image]
            ) { result in
                do {
                    let url = try result.get()
                    guard url.startAccessingSecurityScopedResource() else { return }
                    if let imageData = try? Data(contentsOf: url),
                        let image = UIImage(data: imageData) {
                        albumArtwork = image
                    }
                    url.stopAccessingSecurityScopedResource()
                } catch {
                    print("File selection error: \(error.localizedDescription)")
                }
            }
        }
        .onAppear {
            let metadata = Utils.shared.fetchMetadata(from: selectedFiles)
            for (title, artist, album, artwork, trackNum) in metadata {
                if let artwork = artwork {
                    if albumArtwork == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            albumArtwork = artwork
                        }
                    }
                }
                if let name = album {
                    if albumName.isEmpty {
                        albumName = name
                    }
                }
                if let artist = artist {
                    if artistName.isEmpty {
                        artistName = artist
                    }
                }
                selectedTitles.append(title)
                selectedTrackNums.append(trackNum)
            }
            let sortedIndices = selectedTrackNums.enumerated().sorted { curr, next in
                guard let num0 = curr.element, let num1 = next.element else {
                    return curr.element != nil
                }
                return num0 < num1
            }.map { $0.offset }
            
            selectedTrackNums = sortedIndices.map { selectedTrackNums[$0] }
            selectedFiles = sortedIndices.map { selectedFiles[$0] }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTitles = sortedIndices.map { selectedTitles[$0] }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerAudioPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $albumArtwork)
        }
    }
        
    private func deleteFile(at offsets: IndexSet) {
        selectedFiles.remove(atOffsets: offsets)
        selectedTitles.remove(atOffsets: offsets)
        selectedTrackNums.remove(atOffsets: offsets)
    }

    private func moveFile(from source: IndexSet, to destination: Int) {
        selectedFiles.move(fromOffsets: source, toOffset: destination)
        selectedTitles.move(fromOffsets: source, toOffset: destination)
        selectedTrackNums.move(fromOffsets: source, toOffset: destination)
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.map { guard $0.startAccessingSecurityScopedResource() else { return } }
            selectedFiles.append(contentsOf: urls)
            let metadata = Utils.shared.fetchMetadata(from: urls)
            for (title, artist, album, artwork, trackNum) in metadata {
                if let artwork = artwork {
                    if albumArtwork == nil {
                        albumArtwork = artwork
                    }
                }
                if let name = album {
                    if albumName.isEmpty {
                        albumName = name
                    }
                }
                if let artist = artist {
                    if artistName.isEmpty {
                        artistName = artist
                    }
                }
                selectedTitles.append(title)
                selectedTrackNums.append(trackNum)
            }
            let sortedIndices = selectedTrackNums.enumerated().sorted { curr, next in
                guard let num0 = curr.element, let num1 = next.element else {
                    return curr.element != nil
                }
                return num0 < num1
            }.map { $0.offset }
            
            selectedTrackNums = sortedIndices.map { selectedTrackNums[$0] }
            selectedFiles = sortedIndices.map { selectedFiles[$0] }
            selectedTitles = sortedIndices.map { selectedTitles[$0] }
            
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    private func copyFilesToDocuments(sourceURLs: [URL], name: String) -> (first: [String], last: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var sanitizedAlbumName = name.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
        var filePaths: [String] = []

        if sanitizedAlbumName.isEmpty {
            sanitizedAlbumName = "Untitled"
        }
        
        var albumDirectory = documentsURL.appendingPathComponent(sanitizedAlbumName)
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
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try destinationURL.disableFileProtection()
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        let result = (first: filePaths, last: albumDirectory.lastPathComponent)
        selectedFiles.map { $0.stopAccessingSecurityScopedResource() }
        return result
    }
}
