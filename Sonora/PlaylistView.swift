//
//  PlaylistView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/5/25.
//

import SwiftUI
import AVFoundation

struct PlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var playQueue: PlayQueue
    @State private var isTrackPickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var showDeleteConfirmation = false
    @State private var trackToEdit: Track? = nil
    @State private var tracksToAdd: [Track] = []
    @State private var editMode: EditMode = .inactive
    @State private var isEditingName = false
    @State private var currentTrackIndex: Int?
    @State private var newArtwork: UIImage? = nil
    @State private var preloadedImages: [String?: UIImage?] = [:]
    @State var playlist: Playlist
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let artwork = playlist.artwork {
                    Image(uiImage: UIImage(data: artwork)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .gray, radius: 10)
                } else {
                    Image(systemName: "music.note.list")
                        .font(.title)
                        .frame(width: 200, height: 200)
                        .background(Color.black)
                        .foregroundColor(.gray)
                        .border(.gray, width: 1)
                        .shadow(color: .gray, radius: 10)
                }
                
                if isEditingName {
                    TextField(playlist.name, text: $playlist.name)
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
                    if !playlist.name.isEmpty {
                        Text(playlist.name)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    else {
                        Text("Untitled Playlist")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !playlist.tracklist.isEmpty {
                    let tracklist = playlist.tracklist
                    HStack(spacing: 0) {
                        Button(action: {
                            playQueue.startPlaylistQueueUnshuffled(from: tracklist, playlistName: playlist.name)
                            playlist.lastPlayed = Date.now
                        }) {
                            HStack {
                                Text("Play")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding()
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                        
                        Button(action: {
                            playQueue.startPlaylistQueueShuffled(from: tracklist, playlistName: playlist.name)
                            playlist.lastPlayed = Date.now
                        }) {
                            HStack {
                                Text("Shuffle")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding()
                                Image(systemName: "shuffle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                    }
                }
                
                List {
                    ForEach(Array(playlist.tracklist.enumerated()), id: \.element) { index, element in
                        Button(action: {
                            playQueue.startPlaylistQueue(from: element, in: playlist.tracklist, playlistName: playlist.name)
                            playlist.lastPlayed = Date.now
                        }) {
                            HStack {
                                if !preloadedImages.isEmpty {
                                    if let artworkPath = element.artwork {
                                        if let artwork = preloadedImages[artworkPath]! {
                                            Image(uiImage: artwork)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                        }
                                    }
                                }
                                else {
                                    Image(systemName: "music.note.list")
                                        .font(.subheadline)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.5))
                                }
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(element.title)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                    }
                                    HStack {
                                        Text(element.artist)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                    }
                                }
                                Spacer()
                                Text(element.duration)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Menu {
                                    Button(action: {
                                    }) {
                                        Label("Add To Playlist", systemImage: "plus.square")
                                    }
                                    Button(action: {
                                        playQueue.addToQueue(element)
                                    }) {
                                        Label("Add To Queue", systemImage: "text.badge.plus")
                                    }
                                    Button(action: {
                                        trackToEdit = element
                                    }) {
                                        Label("Edit Track Details", systemImage: "pencil")
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 10)
                                    .frame(width: 25, height: 25)
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        .listRowBackground(Color.black)
                        .frame(height: 40)
                    }
                    .onDelete(perform: editMode.isEditing ? deleteTrack : nil)
                    .onMove(perform: editMode.isEditing ? moveTrack : nil)
                }
                .id(editMode.isEditing)
                .frame(height: CGFloat(120 + playlist.tracklist.count * 62))
                .listStyle(PlainListStyle())
                .scrollDisabled(true)
                .environment(\.editMode, $editMode)
            }
        }
        .onAppear {
            for track in playlist.tracklist {
                let artwork = Utils.shared.loadImageFromDocuments(filePath: track.artwork)
                preloadedImages[track.artwork] = Utils.shared.resizeImageSmall(image: artwork)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if editMode.isEditing || isEditingName {
                    Button(action: {
                        if editMode.isEditing {
                            confirmChanges()
                        }
                        else if isEditingName {
                            confirmNameChanges()
                        }
                    }) {
                        Text("Done")
                            .foregroundColor(.blue)
                    }
                }
                else {
                    Menu {
                        Button(action: {
                            isTrackPickerPresented = true
                        }) {
                            Label("Add Tracks", systemImage: "music.note.list")
                        }
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            Label("Replace Playlist Artwork", systemImage: "photo")
                        }
                        Button(action: {
                            isEditingName = true;
                        }) {
                            Label("Edit Name", systemImage: "pencil")
                        }
                        Button(action: {
                            editMode = .active
                        }) {
                            Label("Edit Tracks", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete Playlist", systemImage: "trash")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                    }
                    .confirmationDialog("Are you sure you want to delete this album?",
                                        isPresented: $showDeleteConfirmation,
                                        titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            PlaylistManager.shared.deletePlaylist(playlist)
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
                    if let newArtwork = newArtwork {
                        let resizedArtwork = Utils.shared.resizeImage(image: newArtwork)
                        playlist.replaceArtwork(resizedArtwork!)
                        PlaylistManager.shared.replacePlaylist(playlist)
                    }
                }
        }
        .sheet(isPresented: $isTrackPickerPresented) {
            TrackPickerView(isPresented: $isTrackPickerPresented, selectedTracks: $tracksToAdd)
                .onDisappear {
                    let artworkPaths = tracksToAdd.map { $0.artwork }
                    let artworks = artworkPaths.map { Utils.shared.loadImageFromDocuments(filePath: $0) }
                    for (index, artwork) in artworks.enumerated() {
                        preloadedImages[artworkPaths[index]] = artwork
                    }
                    playlist.tracklist.append(contentsOf: tracksToAdd)
                    PlaylistManager.shared.replacePlaylist(playlist)
                }
        }
        .sheet(item: $trackToEdit) { track in
            if let index = playlist.tracklist.firstIndex(where: { $0.id == track.id }) {
                EditTrackView(playlist: playlist, track: track, trackIndex: index)
                    .onDisappear {
                        playlist = PlaylistManager.shared.fetchPlaylist(playlist.id)
                        let artworkPath = playlist.tracklist[index].artwork
                        let artwork = Utils.shared.loadImageFromDocuments(filePath: artworkPath)
                        preloadedImages[artworkPath] = artwork
                    }
            }
        }
    }
    
    private func deleteTrack(at offsets: IndexSet) {
        playlist.tracklist.remove(atOffsets: offsets)
    }
    
    private func moveTrack(from source: IndexSet, to destination: Int) {
        playlist.tracklist.move(fromOffsets: source, toOffset: destination)
    }
    
    private func confirmChanges() {
        PlaylistManager.shared.replacePlaylist(playlist)
        editMode = .inactive
    }
    
    private func confirmNameChanges() {
        PlaylistManager.shared.replacePlaylist(playlist)
        isEditingName = false
    }
}
