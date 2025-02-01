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
    @State private var editMode: EditMode = .inactive
    @State private var albumName: String = ""
    @State private var artists: String = ""
    @State private var albumArtwork: UIImage? = nil
    @State private var selectedFiles: [URL] = []
    @State private var isFilePickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var originalFiles: [URL] = []

    var body: some View {
        NavigationView {
            GeometryReader { _ in
                VStack {
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
                            TextField("", text: $artists)
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

                    VStack(spacing: 0) {
                        if !selectedFiles.isEmpty {
                            HStack {
                                if editMode.isEditing {
                                    Button(action: {
                                        cancelChanges()
                                    }) {
                                        Text("Cancel")
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    Button(action: {
                                        editMode = editMode == .active ? .inactive : .active
                                        originalFiles = selectedFiles
                                    }) {
                                        Text("Edit")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Spacer()

                                if editMode.isEditing {
                                    Button(action: {
                                        confirmChanges()
                                    }) {
                                        Text("Done")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding([.leading, .trailing])
                        }
                        
                        List {
                            ForEach(Array(selectedFiles.enumerated()), id: \.element) { index, element in
                                HStack {
                                    Text(element.deletingPathExtension().lastPathComponent)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    Text("\(index+1)")
                                        .foregroundColor(.gray)
                                }
                                .padding([.leading, .trailing])
                                .listRowInsets(EdgeInsets())
                            }
                            .onDelete(perform: editMode.isEditing ? deleteFile: nil)
                            .onMove(perform: editMode.isEditing ? moveFile: nil)
                        }
                        .id(editMode.isEditing)
                        .environment(\.editMode, $editMode)
                        .padding(.top, 5)
                        .listStyle(PlainListStyle())
                    }
                    .padding(.top, 5)
                    
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isFilePickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Files")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(.blue)
                        .cornerRadius(8)
                    }
                    .padding()
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
        
    private func cancelChanges() {
        selectedFiles = originalFiles
        editMode = .inactive
    }

    private func confirmChanges() {
        originalFiles = selectedFiles
        editMode = .inactive
    }
        
    private func deleteFile(at offsets: IndexSet) {
        selectedFiles.remove(atOffsets: offsets)
        if selectedFiles.isEmpty {
            editMode = .inactive
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
        var sanitizedAlbumName = name.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
        var filePaths: [String] = []

        if sanitizedAlbumName.isEmpty {
            sanitizedAlbumName = "Untitled"
        }
        
        var albumDirectory = documentsURL.appendingPathComponent(sanitizedAlbumName)
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
