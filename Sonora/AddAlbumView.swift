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
    @State private var albumName: String = ""
    @State private var artist: String = ""
    @State private var albumArtwork: UIImage? = nil
    @State private var selectedFiles: [URL] = []
    @State private var isFilePickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var originalFiles: [URL] = []

    var body: some View {
        NavigationView {
            GeometryReader { _ in
                ScrollView {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isImagePickerPresented = true
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
                        }
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Artist(s)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            TextField("", text: $artist)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.gray),
                                    alignment: .bottom
                                )
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding(.top, 10)

                    List {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        ForEach(Array(selectedFiles.enumerated()), id: \.element) { index, element in
                            HStack {
                                Text(element.deletingPathExtension().lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text("\(index+1)")
                                    .foregroundColor(.gray)
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
                        let resizedArtwork = Utils.shared.resizeImage(image: albumArtwork)
                        let artworkPath = Utils.shared.copyImageToDocuments(artwork: resizedArtwork, directory: directory)
                        let newAlbum = Album(name: albumName, artist: artist, artwork: artworkPath, tracks: filePaths, directory: directory)
                        AlbumManager.shared.saveAlbum(newAlbum)
                        showPopup = "Created album"
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
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
        
    private func deleteFile(at offsets: IndexSet) {
        selectedFiles.remove(atOffsets: offsets)
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
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        let result = (first: filePaths, last: albumDirectory.lastPathComponent)
        return result
    }
}
