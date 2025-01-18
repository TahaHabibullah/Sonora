//
//  AddAlbumView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/16/25.
//

import SwiftUI

struct AddAlbumView: View {
    @Binding var isPresented: Bool
    @State private var albumName: String = ""
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
                    ForEach(selectedFiles, id: \.self) { file in
                        Text(file.deletingPathExtension().lastPathComponent)
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
                    let newAlbum = Album(name: albumName, artwork: albumArtwork, tracks: selectedFiles)
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
            selectedFiles.append(contentsOf: urls)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}
