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
    @State private var isAddToPlaylistPresented = false
    @State private var isFilePickerImagesPresented = false
    @State private var showImportOptions = false
    @State private var showDeleteConfirmation = false
    @State private var editMode: EditMode = .inactive
    @State private var isEditingName = false
    @State private var isEditingArtist = false
    @State private var trackToEdit: Track? = nil
    @State private var trackToAdd: Track? = nil
    @State private var newTitle: String = ""
    @State private var newArtist: String = ""
    @State private var newArtwork: UIImage? = nil
    @State private var artworkUrl: URL?
    @State private var markedForDeletion: [Track] = []
    @State private var showPopup: String = ""
    @State private var tracklist: [Track] = []
    @State var album: Album
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var artistFieldFocused: Bool
    @FocusState private var trackFieldFocused: Bool
    let haptics = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let artwork = Utils.shared.loadImageFromDocuments(filePath: album.artwork) {
                    Image(uiImage: artwork)
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
                        .autocorrectionDisabled(true)
                }
                else {
                    if !album.name.isEmpty {
                        Text(album.name)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    else {
                        Text("Untitled Album")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                if isEditingArtist {
                    TextField(album.artist, text: $newArtist)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .focused($artistFieldFocused)
                        .onAppear {
                            newArtist = album.artist
                            artistFieldFocused = true
                        }
                        .autocorrectionDisabled(true)
                }
                else {
                    if !album.artist.isEmpty {
                        Text(album.artist)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    else {
                        Text("Unknown Artist")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !tracklist.isEmpty {
                    HStack(spacing: 0) {
                        Button(action: {
                            haptics.impactOccurred()
                            playQueue.startUnshuffledQueue(tracks: tracklist, playlistName: album.name)
                            album.lastPlayed = Date.now
                            AlbumManager.shared.replaceAlbum(album)
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
                            playQueue.startShuffledQueue(tracks: tracklist, playlistName: album.name)
                            album.lastPlayed = Date.now
                            AlbumManager.shared.replaceAlbum(album)
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
                    ForEach(tracklist, id: \.self) { track in
                        Button(action: {
                            playQueue.startUnshuffledQueue(from: track, tracks: tracklist, playlistName: album.name)
                            album.lastPlayed = Date.now
                            AlbumManager.shared.replaceAlbum(album)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(track.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    
                                    Text(track.artist)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Spacer()
                                Text(Utils.shared.getTrackDuration(from: track.path))
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
                                }
                                .contentShape(Rectangle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    haptics.impactOccurred()
                                })
                            }
                            .frame(height: 40)
                        }
                    }
                    .onDelete(perform: editMode.isEditing ? deleteFile : nil)
                    .onMove(perform: editMode.isEditing ? moveFile : nil)
                }
                .id(editMode.isEditing)
                .scrollDisabled(true)
                .frame(height: CGFloat(120 + tracklist.count * 62))
                .environment(\.editMode, $editMode)
                .listStyle(PlainListStyle())
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
                    if editMode.isEditing || isEditingName || isEditingArtist {
                        Button(action: {
                            if editMode.isEditing {
                                confirmChanges()
                            }
                            else if isEditingName {
                                confirmNameChanges()
                            }
                            else if isEditingArtist {
                                confirmArtistChanges()
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
                                Label("Add Files to Album", systemImage: "music.note.list")
                            }
                            Button(action: {
                                showImportOptions = true
                            }) {
                                Label("Replace Album Artwork", systemImage: "photo")
                            }
                            Button(action: {
                                isEditingName = true;
                            }) {
                                Label("Edit Title", systemImage: "pencil")
                            }
                            Button(action: {
                                isEditingArtist = true;
                            }) {
                                Label("Edit Artist", systemImage: "pencil")
                            }
                            Button(action: {
                                editMode = .active
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
                        .simultaneousGesture(TapGesture().onEnded {
                            haptics.impactOccurred()
                        })
                        .confirmationDialog("Are you sure you want to delete this album?",
                                            isPresented: $showDeleteConfirmation,
                                            titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                AlbumManager.shared.deleteAlbum(album)
                                TrackManager.shared.deleteAlbumTracklist(from: album.directory)
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
                        guard newArtwork != nil else { return }
                        let resizedArtwork = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 600, height: 600))
                        let resizedArtworkSmall = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 100, height: 100))
                        Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: album.directory)
                        let artworkPath = album.artwork
                        let smallArtworkPath = album.smallArtwork
                        album.artwork = ""
                        album.smallArtwork = ""
                        album.artwork = artworkPath
                        album.smallArtwork = smallArtworkPath
                    }
            }
            .sheet(item: $trackToAdd) { track in
                AddToPlaylistView(showPopup: $showPopup, track: track)
            }
            .sheet(item: $trackToEdit) { track in
                EditTrackView(track: track)
                    .onDisappear {
                        tracklist = TrackManager.shared.fetchTracks(key: album.directory)
                        if let index = tracklist.firstIndex(where: { $0.id == track.id }) {
                            let artwork = tracklist[index].artwork
                            let smallArtwork = tracklist[index].smallArtwork
                            tracklist[index].artwork = ""
                            tracklist[index].smallArtwork = ""
                            tracklist[index].artwork = artwork
                            tracklist[index].smallArtwork = smallArtwork
                        }
                    }
            }
            .sheet(isPresented: $isFilePickerImagesPresented) {
                ImageDocumentPicker(imageURL: $artworkUrl)
                    .onDisappear {
                        if let url = artworkUrl {
                            guard url.startAccessingSecurityScopedResource() else { return }
                            if let imageData = try? Data(contentsOf: url),
                               let image = UIImage(data: imageData) {
                                let resizedArtwork = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 600, height: 600))
                                let resizedArtworkSmall = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 100, height: 100))
                                Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: album.directory)
                                let artworkPath = album.artwork
                                let smallArtworkPath = album.smallArtwork
                                album.artwork = ""
                                album.smallArtwork = ""
                                album.artwork = artworkPath
                                album.smallArtwork = smallArtworkPath
                            }
                            url.stopAccessingSecurityScopedResource()
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
            tracklist = TrackManager.shared.fetchTracks(key: album.directory)
        }
    }
    
    private func deleteFile(at offsets: IndexSet) {
        markedForDeletion.append(tracklist[offsets.first!])
        tracklist.remove(atOffsets: offsets)
    }
    
    private func confirmChanges() {
        if !markedForDeletion.isEmpty {
            deleteFilesFromDocuments(tracks: markedForDeletion)
            TrackManager.shared.deleteTracksFromAlbum(from: album.directory,
                                                      with: markedForDeletion.map { $0.id })
        }
        TrackManager.shared.replaceTracklist(tracklist, for: album.directory)
        editMode = .inactive
    }
    
    private func confirmNameChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditingName = false
    }
    
    private func confirmArtistChanges() {
        album.artist = newArtist
        for i in 0..<tracklist.count {
            tracklist[i].artist = newArtist
        }
        TrackManager.shared.replaceTracklist(tracklist, for: album.directory)
        AlbumManager.shared.replaceAlbum(album)
        isEditingArtist = false
    }
    
    private func moveFile(from source: IndexSet, to destination: Int) {
        tracklist.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteFilesFromDocuments(tracks: [Track]) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for track in tracks {
            do {
                let trackPath = documentsURL.appendingPathComponent(track.path)
                if fileManager.fileExists(atPath: trackPath.path) {
                    try fileManager.removeItem(at: trackPath)
                }
                if track.artwork != album.artwork {
                    let artworkPath = documentsURL.appendingPathComponent(track.artwork)
                    let smallArtworkPath = documentsURL.appendingPathComponent(track.smallArtwork)
                    if fileManager.fileExists(atPath: artworkPath.path) {
                        try fileManager.removeItem(at: artworkPath)
                        try fileManager.removeItem(at: smallArtworkPath)
                    }
                }
            } catch {
                print("Failed to delete file at path: \(track.path)")
            }
        }
        markedForDeletion.removeAll()
    }
    
    private func copyFilesToDocuments(sourceURLs: [URL], name: String) -> [String] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let albumDirectory = documentsURL.appendingPathComponent(album.directory)
        var filePaths: [String] = []
        
        for sourceURL in sourceURLs {
            let destinationURL = albumDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            let filePath = album.directory + "/" + sourceURL.lastPathComponent
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
            
            do {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try destinationURL.disableFileProtection()
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        sourceURLs.map { $0.stopAccessingSecurityScopedResource() }
        return filePaths
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.map { $0.startAccessingSecurityScopedResource() }
            let filePaths = copyFilesToDocuments(sourceURLs: urls, name: album.name)
            let newTracks = filePaths.map { Track(artist: album.artist,
                                                  artwork: album.artwork,
                                                  smallArtwork: album.smallArtwork,
                                                  path: $0) }
            tracklist.append(contentsOf: newTracks)
            TrackManager.shared.replaceTracklist(tracklist, for: album.directory)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}
