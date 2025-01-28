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
    @State private var albumName: String = ""
    @State private var artists: String = ""
    @State private var albumArtwork: UIImage? = nil
    @State private var selectedFiles: [URL] = []
    @State private var isFilePickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var isEditing = false
    @State private var originalFiles: [URL] = []

    var body: some View {
        NavigationView {
            VStack {
                TextField("Album Name", text: $albumName)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding([.leading, .trailing])
                
                TextField("Artist(s)", text: $artists)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding([.leading, .trailing])

                ZStack(alignment: .topLeading) {
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        if let albumArtwork = albumArtwork {
                            Image(uiImage: albumArtwork)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        } else {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                Text("Add Album Artwork")
                                    .font(.subheadline)
                                    .padding(.top, 5)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                    
                    if albumArtwork != nil {
                        Button(action: {
                            albumArtwork = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .padding(8)
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                        .padding(8)
                    }
                }
                .padding()

                if !selectedFiles.isEmpty {
                    HStack {
                        if isEditing {
                            Button(action: {
                                cancelChanges()
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Button(action: {
                                isEditing = true
                                originalFiles = selectedFiles
                            }) {
                                Text("Edit")
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()

                        if isEditing {
                            Button(action: {
                                confirmChanges()
                            }) {
                                Text("Done")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding(.bottom, 0)
                }
                
                List {
                    ForEach(Array(selectedFiles.enumerated()), id: \.element) { index, element in
                        HStack {
                            Text("\(index+1)")
                                .foregroundColor(.gray)
                            Text(element.deletingPathExtension().lastPathComponent)
                                .padding(.leading, 10)
                            Spacer()
                            Text(getTrackDuration(from: element))
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete(perform: isEditing ? deleteFile : nil)
                    .onMove(perform: isEditing ? moveFile : nil)
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Files")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
                }
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
                    let directory  = tuple.last
                    let newAlbum = Album(name: albumName, artists: artists, artwork: albumArtwork, tracks: filePaths, directory: directory)
                    AlbumManager.shared.saveAlbum(newAlbum)
                    isPresented = false
                }
                .foregroundColor(.blue)
            )
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $albumArtwork)
        }
    }
    
    func getTrackDuration(from url: URL) -> String {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        if durationInSeconds.isFinite {
            let minutes = Int(durationInSeconds) / 60
            let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
            let stringSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "\(minutes):\(stringSeconds)"
        } else {
            return ""
        }
    }
        
    private func cancelChanges() {
        selectedFiles = originalFiles
        isEditing = false
    }

    private func confirmChanges() {
        originalFiles = selectedFiles
        isEditing = false
    }
        
    private func deleteFile(at offsets: IndexSet) {
        selectedFiles.remove(atOffsets: offsets)
        if selectedFiles.isEmpty {
            isEditing = false
        }
    }

    private func moveFile(from source: IndexSet, to destination: Int) {
        selectedFiles.move(fromOffsets: source, toOffset: destination)
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.map { $0.startAccessingSecurityScopedResource() }
            selectedFiles.append(contentsOf: urls)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    func directoryExists(at path: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func copyFilesToDocuments(sourceURLs: [URL], name: String) -> (first: [String], last: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sanitizedAlbumName = name.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
        var albumDirectory = documentsURL.appendingPathComponent(sanitizedAlbumName)
        var filePaths: [String] = []

        var count = 1
        while directoryExists(at: albumDirectory) {
            if count > 1 {
                let newDirectory = albumDirectory.path.replacingOccurrences(of: "\(sanitizedAlbumName)__\(count-1)", with: "\(sanitizedAlbumName)__\(count)")
                albumDirectory = URL(fileURLWithPath: newDirectory)
            }
            else {
                let newDirectory = albumDirectory.path.replacingOccurrences(of: "\(sanitizedAlbumName)", with: "\(sanitizedAlbumName)__1")
                albumDirectory = URL(fileURLWithPath: newDirectory)
            }
            count+=1
        }
        
        do {
            try fileManager.createDirectory(at: albumDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        for sourceURL in sourceURLs {
            let destinationURL = albumDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            let filePath = count > 1 ? sanitizedAlbumName + "__\(count-1)/" + sourceURL.lastPathComponent : sanitizedAlbumName + "/" + sourceURL.lastPathComponent
            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
           
            do {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        let result = (first: filePaths, last: albumDirectory.lastPathComponent)
        return result
   }
}
