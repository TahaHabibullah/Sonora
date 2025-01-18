//
//  Library.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @State private var isAddAlbumPresented = false
    @State private var isAddMenuPresented = false
    @State private var albums: [Album] = []
    
    var body: some View {
        VStack() {
            NavigationView {
                VStack {
                    List(albums) { album in
                        NavigationLink(destination: AlbumView(album: album)) {
                            HStack {
                                if let artworkData = album.artwork,
                                   let artwork = UIImage(data: artworkData) {
                                    Image(uiImage: artwork)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "photo")
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                VStack(alignment: .leading) {
                                    Text(album.name)
                                        .font(.headline)
                                    Text("\(album.tracks.count) tracks")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle("Library")
                    .onAppear {
                        albums = AlbumManager.shared.fetchAlbums()
                    }
                }
                .contentMargins(.top, 40)
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                print("Add loose tracks tapped")
                            }) {
                                Label("Add files to library", systemImage: "music.note.list")
                            }

                            Button(action: {
                                isAddAlbumPresented = true
                            }) {
                                Label("Create new album", systemImage: "plus.rectangle.on.rectangle")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                .font(.title2)
                            }
                            .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $isAddAlbumPresented) {
                            AddAlbumView(isPresented: $isAddAlbumPresented)
                        }
                        .padding()
                    }
                }
            }
        }
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

extension URL {
    var mimeType: String? {
        let pathExtension = self.pathExtension
        guard !pathExtension.isEmpty else { return nil }
        let uti = UTType(filenameExtension: pathExtension)
        return uti?.preferredMIMEType
    }
}

