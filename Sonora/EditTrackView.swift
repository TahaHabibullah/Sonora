//
//  EditTrackView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/3/25.
//

import SwiftUI

struct EditTrackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var track: Track
    @State var playlist: Playlist?
    var trackIndex: Int?
    @State private var newArtwork: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var isFilePickerImagesPresented = false
    @State private var showImportOptions = false
    
    init(playlist: Playlist? = nil, track: Track, trackIndex: Int? = nil) {
        self.playlist = playlist
        self.track = track
        self.trackIndex = trackIndex
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { _ in
                VStack {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showImportOptions = true
                    }) {
                        ZStack {
                            if let artwork = newArtwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                            }
                            else if let artwork = Utils.shared.loadImageFromDocuments(filePath: track.artwork) {
                                Image(uiImage: artwork)
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
                    }
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Track Title")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            TextField(track.title, text: $track.title)
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
                            TextField(track.artist, text: $track.artist)
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
                .navigationTitle("Edit Track")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue),
                    trailing: Button("Save") {
                        if let index = trackIndex {
                            playlist!.tracklist[index] = track
                            PlaylistManager.shared.replacePlaylist(playlist!)
                        }
                        else {
                            TrackManager.shared.replaceTrack(track)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
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
                    newArtwork = image
                    let resizedArtwork = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 600, height: 600))
                    let resizedArtworkSmall = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 100, height: 100))
                    let tuple = Utils.shared.copyLooseTrackImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, trackPath: track.path)
                    track.artwork = tuple.first
                    track.smallArtwork = tuple.last
                }
                url.stopAccessingSecurityScopedResource()
            } catch {
                print("File selection error: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $newArtwork)
                .onDisappear {
                    guard newArtwork != nil else { return }
                    let resizedArtwork = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 600, height: 600))
                    let resizedArtworkSmall = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 100, height: 100))
                    let tuple = Utils.shared.copyLooseTrackImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, trackPath: track.path)
                    track.artwork = tuple.first
                    track.smallArtwork = tuple.last
                }
        }
    }
}
