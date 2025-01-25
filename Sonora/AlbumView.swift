//
//  AlbumView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/17/25.
//
import SwiftUI
import AVFoundation

struct AlbumView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var playQueue: PlayQueue
    @State private var isFilePickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @State private var isEditingName = false
    @State private var isEditingArtists = false
    @State private var editingTrackIndex: Int? = nil
    @State private var currentTrackIndex: Int?
    @State private var newArtwork: UIImage? = nil
    @State var album: Album
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var artistFieldFocused: Bool
    @FocusState private var trackFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let artworkData = album.artwork,
                    let artwork = UIImage(data: artworkData) {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .gray, radius: 10)
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.gray.opacity(0.3))
                }
                
                if isEditingName {
                    TextField(album.name, text: $album.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .focused($nameFieldFocused)
                        .onAppear {
                            nameFieldFocused = true
                        }
                }
                else {
                    Text(album.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                if isEditingArtists {
                    TextField(album.artists, text: $album.artists)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .focused($artistFieldFocused)
                        .onAppear {
                            artistFieldFocused = true
                        }
                }
                else {
                    Text(album.artists)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }

                List {
                    ForEach(Array(album.tracks.enumerated()), id: \.element) { index, element in
                        Button(action: {
                            playQueue.startQueue(from: element, in: album)
                        }) {
                            HStack {
                                Text("\(index+1)")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                if editingTrackIndex == index {
                                    TextField(album.titles[index], text: $album.titles[index])
                                        .focused($trackFieldFocused)
                                        .onAppear {
                                            trackFieldFocused = true
                                        }
                                }
                                else {
                                    Text(album.titles[index])
                                }
                                Spacer()
                                Text(getTrackDuration(from: element))
                                    .foregroundColor(.gray)
                            
                                if editingTrackIndex == index {
                                    Button(action: {
                                        confirmTrackChanges()
                                        editingTrackIndex = nil
                                    }) {
                                        Image(systemName: "checkmark")
                                            .padding()
                                            .foregroundColor(.blue)
                                    }
                                }
                                else {
                                    Menu {
                                        Button(action: {
                                        }) {
                                            Label("Add to Playlist", systemImage: "plus.square")
                                        }
                                        Button(action: {
                                            editingTrackIndex = index
                                        }) {
                                            Label("Rename Track", systemImage: "pencil")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                        .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    .onDelete(perform: isEditing ? deleteFile : nil)
                    .onMove(perform: isEditing ? moveFile : nil)
                }
                .scrollDisabled(true)
                .frame(height: CGFloat(album.tracks.count * 60))
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                .listStyle(PlainListStyle())
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing || isEditingName || isEditingArtists {
                        Button(action: {
                            if isEditing {
                                confirmChanges()
                            }
                            else if isEditingName {
                                confirmNameChanges()
                            }
                            else if isEditingArtists {
                                confirmArtistsChanges()
                            }
                        }) {
                            Text("Done")
                                .foregroundColor(.blue)
                        }
                    }
                    else {
                        Menu {
                            Button(action: {
                                isFilePickerPresented = true
                            }) {
                                Label("Add Files to Album", systemImage: "document.badge.plus")
                            }
                            Button(action: {
                                isImagePickerPresented = true
                            }) {
                                Label("Replace Album Artwork", systemImage: "photo")
                            }
                            Button(action: {
                                isEditingName = true;
                            }) {
                                Label("Edit Title", systemImage: "pencil")
                            }
                            Button(action: {
                                isEditingArtists = true;
                            }) {
                                Label("Edit Artists", systemImage: "pencil")
                            }
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("Edit Tracks", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete Album", systemImage: "trash")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "ellipsis.circle")
                                .font(.headline)
                            }
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .confirmationDialog("Are you sure you want to delete this album?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                AlbumManager.shared.deleteAlbum(album)
                                presentationMode.wrappedValue.dismiss()
                                showDeleteConfirmation = false
                            }
                            Button("Cancel", role: .cancel) {
                                showDeleteConfirmation = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $newArtwork)
                    .onDisappear() {
                        if newArtwork != nil {
                            album.replaceArtwork(newArtwork!)
                            AlbumManager.shared.replaceAlbum(album)
                        }
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
    
    private func deleteFile(at offsets: IndexSet) {
        album.tracks.remove(atOffsets: offsets)
        album.titles.remove(atOffsets: offsets)
    }
    
    private func confirmChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditing = false
    }
    
    private func confirmNameChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditingName = false
    }
    
    private func confirmArtistsChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditingArtists = false
    }
    
    private func confirmTrackChanges() {
        AlbumManager.shared.replaceAlbum(album)
        editingTrackIndex = nil
    }

    private func moveFile(from source: IndexSet, to destination: Int) {
        album.tracks.move(fromOffsets: source, toOffset: destination)
        album.titles.move(fromOffsets: source, toOffset: destination)
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            album.tracks.append(contentsOf: urls)
            album.titles.append(contentsOf: urls.map { $0.deletingPathExtension().lastPathComponent})
            AlbumManager.shared.replaceAlbum(album)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}
