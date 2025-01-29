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
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack() {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(albums) { album in
                            NavigationLink(destination: AlbumView(album: album)) {
                                VStack(spacing: 0) {
                                    if let artwork = album.artwork {
                                        Image(uiImage: UIImage(data: artwork)!)
                                            .resizable()
                                            .scaledToFit()
                                            .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                    } else {
                                        Image(systemName: "music.note.list")
                                            .font(.title)
                                            .frame(width: 178, height: 178)
                                            .background(Color.black)
                                            .foregroundColor(.gray)
                                            .border(.gray, width: 1)
                                            .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                    }
                                    VStack(spacing: 0) {
                                        if !album.name.isEmpty {
                                            Text(album.name)
                                                .foregroundColor(.white)
                                                .font(.subheadline)
                                                .bold()
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        else {
                                            Text("Untitled Album")
                                                .foregroundColor(.white)
                                                .font(.subheadline)
                                                .bold()
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        if !album.artists.isEmpty {
                                            Text(album.artists)
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        else {
                                            Text("Unknown Artist")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    albums = AlbumManager.shared.fetchAlbums()
                }
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
                                .onDisappear {
                                    albums = AlbumManager.shared.fetchAlbums()
                                }
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

