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
    @State private var isFilePickerImagesPresented = false
    @State private var showImportOptions = false
    @State private var isEditTracklistPresented = false
    @State private var showDeleteConfirmation = false
    @State private var showPopup: String = ""
    @State private var trackToEdit: Track? = nil
    @State private var trackToAdd: Track? = nil
    @State private var tracksToAdd: [Track] = []
    @State private var isEditingName = false
    @State private var newArtwork: UIImage? = nil
    @State private var tracklist: [Track] = []
    @State var playlist: Playlist
    @FocusState private var nameFieldFocused: Bool
    let haptics = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let artwork = playlist.artwork {
                    Image(uiImage: UIImage(data: artwork)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .gray, radius: 10)
                        .animation(nil)
                } else {
                    Image(systemName: "music.note.list")
                        .font(.title)
                        .frame(width: 200, height: 200)
                        .background(Color.black)
                        .foregroundColor(.gray)
                        .border(.gray, width: 1)
                        .shadow(color: .gray, radius: 10)
                        .animation(nil)
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
                
                HStack {
                    Spacer()
                    Text("\(tracklist.count) Tracks  |  \(playlist.duration)")
                        .font(.caption)
                    Spacer()
                }
                .padding(.top, 5)
                .foregroundColor(.gray)
                
                if !tracklist.isEmpty {
                    HStack(spacing: 0) {
                        Button(action: {
                            haptics.impactOccurred()
                            playQueue.startPlaylistQueueUnshuffled(from: tracklist, playlistName: playlist.name)
                            playlist.lastPlayed = Date.now
                            PlaylistManager.shared.replacePlaylist(playlist)
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
                            haptics.impactOccurred()
                            playQueue.startPlaylistQueueShuffled(from: tracklist, playlistName: playlist.name)
                            playlist.lastPlayed = Date.now
                            PlaylistManager.shared.replacePlaylist(playlist)
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
                    
                ForEach(tracklist, id: \.self) { track in
                    Button(action: {
                        playQueue.startPlaylistQueue(from: track, in: tracklist, playlistName: playlist.name)
                        playlist.lastPlayed = Date.now
                        PlaylistManager.shared.replacePlaylist(playlist)
                    }) {
                        HStack {
                            if let artwork = Utils.shared.loadImageFromDocuments(filePath: track.smallArtwork) {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .padding(.leading, 15)
                                    .animation(nil)
                            }
                            else {
                                Image(systemName: "music.note.list")
                                    .font(.subheadline)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.leading, 15)
                                    .animation(nil)
                            }
                            VStack(spacing: 0) {
                                HStack {
                                    Text(track.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                }
                                HStack {
                                    if !track.artist.isEmpty {
                                        Text(track.artist)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    else {
                                        Text("Unknown Artist")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                            Text(track.duration)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Menu {
                                Button(action: {
                                    trackToAdd = track
                                }) {
                                    Label("Add To Playlist", systemImage: "plus.square")
                                }
                                Button(action: {
                                    playQueue.addToQueue(track)
                                    withAnimation(.linear(duration: 0.25)) {
                                        showPopup = "Added to queue"
                                    }
                                }) {
                                    Label("Add To Queue", systemImage: "text.badge.plus")
                                }
                                Button(action: {
                                    trackToEdit = track
                                }) {
                                    Label("Edit Track Details", systemImage: "pencil")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 35, height: 50)
                                .padding(.trailing, 5)
                            }
                            .contentShape(Rectangle())
                            .simultaneousGesture(TapGesture().onEnded {
                                haptics.impactOccurred()
                            })
                        }
                    }
                    .frame(height: 65)
                    .padding(.trailing, 10)
                    .foregroundColor(.white)
                }
            }
            .padding(.bottom, 60)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditingName {
                    Button(action: {
                        if isEditingName {
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
                            showImportOptions = true
                        }) {
                            Label("Replace Playlist Artwork", systemImage: "photo")
                        }
                        Button(action: {
                            isEditingName = true;
                        }) {
                            Label("Edit Name", systemImage: "pencil")
                        }
                        Button(action: {
                            isEditTracklistPresented = true
                        }) {
                            Label("Edit Tracklist", systemImage: "pencil")
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
                    .simultaneousGesture(TapGesture().onEnded {
                        haptics.impactOccurred()
                    })
                    .confirmationDialog("Are you sure you want to delete this playlist?",
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
        .overlay {
            if !showPopup.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline)
                        Text(showPopup)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                    .padding(.bottom, 60)
                    .transition(.opacity)
                    .onAppear {
                        let haptics = UINotificationFeedbackGenerator()
                        haptics.notificationOccurred(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showPopup = ""
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            tracklist = TrackManager.shared.fetchPlaylist(from: playlist.tracklist)
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
                    let resizedArtwork = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 400, height: 400))
                    playlist.replaceArtwork(resizedArtwork!)
                    PlaylistManager.shared.replacePlaylist(playlist)
                }
                url.stopAccessingSecurityScopedResource()
            } catch {
                print("File selection error: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $newArtwork)
                .onDisappear() {
                    if let newArtwork = newArtwork {
                        let resizedArtwork = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 400, height: 400))
                        playlist.replaceArtwork(resizedArtwork!)
                        PlaylistManager.shared.replacePlaylist(playlist)
                    }
                }
        }
        .sheet(isPresented: $isTrackPickerPresented) {
            let currentIds = playlist.tracklist
            TrackPickerView(isPresented: $isTrackPickerPresented, selectedTracks: $tracksToAdd, currentIds: Set(currentIds))
                .onDisappear {
                    playlist.tracklist.append(contentsOf: tracksToAdd.map { $0.id })
                    tracklist.append(contentsOf: tracksToAdd)
                    playlist.duration = Utils.shared.getPlaylistDuration(from: tracklist.map { $0.path })
                    PlaylistManager.shared.replacePlaylist(playlist)
                    tracksToAdd = []
                }
        }
        .sheet(isPresented: $isEditTracklistPresented) {
            EditTracklistView(isPresented: $isEditTracklistPresented, tracklist: $tracklist, playlist: playlist)
                .onDisappear {
                    playlist = PlaylistManager.shared.fetchPlaylist(playlist.id)
                }
        }
        .sheet(item: $trackToEdit) { track in
            if let index = playlist.tracklist.firstIndex(where: { $0 == track.id }) {
                EditTrackView(playlist: playlist, track: track)
                    .onDisappear {
                        tracklist = TrackManager.shared.fetchPlaylist(from: playlist.tracklist)
                        let newArtwork = tracklist[index].artwork
                        let newArtworkSmall = tracklist[index].smallArtwork
                        tracklist[index].artwork = ""
                        tracklist[index].smallArtwork = ""
                        tracklist[index].artwork = newArtwork
                        tracklist[index].smallArtwork = newArtworkSmall
                    }
            }
        }
        .sheet(item: $trackToAdd) { track in
            AddToPlaylistView(showPopup: $showPopup, track: track)
        }
    }
    
    private func confirmNameChanges() {
        PlaylistManager.shared.replacePlaylist(playlist)
        isEditingName = false
    }
}
