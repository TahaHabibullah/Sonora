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
    @State private var isEditingArtists = false
    @State private var editingTrackIndex: Int? = nil
    @State private var trackToAdd: Track? = nil
    @State private var newTitle: String = ""
    @State private var newArtist: String = ""
    @State private var newArtwork: UIImage? = nil
    @State private var artworkUrl: URL?
    @State private var markedForDeletion: [Track] = []
    @State private var showPopup: String = ""
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
                if isEditingArtists {
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
                        Text("Unkown Artist")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !album.tracklist.isEmpty {
                    HStack(spacing: 0) {
                        Button(action: {
                            haptics.impactOccurred()
                            playQueue.startQueue(from: 0, in: album)
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
                            playQueue.startShuffledQueue(from: album)
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
                    ForEach(Array(album.tracklist.enumerated()), id: \.element) { index, element in
                        Button(action: {
                            playQueue.startQueue(from: index, in: album)
                            album.lastPlayed = Date.now
                            AlbumManager.shared.replaceAlbum(album)
                        }) {
                            HStack {
                                if editingTrackIndex == index {
                                    TextField(element.title, text: $newTitle)
                                        .font(.subheadline)
                                        .focused($trackFieldFocused)
                                        .onAppear {
                                            newTitle = element.title
                                            trackFieldFocused = true
                                        }
                                }
                                else {
                                    Text(element.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Spacer()
                                Text(Utils.shared.getTrackDuration(from: element.path))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                if editingTrackIndex == index {
                                    Button(action: {
                                        album.tracklist[index].title = newTitle
                                        confirmTrackChanges()
                                    }) {
                                        Image(systemName: "checkmark")
                                            .frame(width: 35, height: 50)
                                            .foregroundColor(.blue)
                                    }
                                }
                                else {
                                    Menu {
                                        Button(action: {
                                            trackToAdd = Track(artist: album.artist,
                                                               title: element.title,
                                                               artwork: album.artwork,
                                                               smallArtwork: album.smallArtwork,
                                                               path: element.path)
                                        }) {
                                            Label("Add To Playlist", systemImage: "plus.square")
                                        }
                                        Button(action: {
                                            playQueue.addToQueue(Track(artist: album.artist,
                                                                       title: element.title,
                                                                       artwork: album.artwork,
                                                                       smallArtwork: album.smallArtwork,
                                                                       path: element.path))
                                            withAnimation(.linear(duration: 0.25)) {
                                                showPopup = "Added to queue"
                                            }
                                        }) {
                                            Label("Add To Queue", systemImage: "text.badge.plus")
                                        }
                                        Button(action: {
                                            editingTrackIndex = index
                                        }) {
                                            Label("Rename Track", systemImage: "pencil")
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
                            }
                            .frame(height: 40)
                        }
                    }
                    .onDelete(perform: editMode.isEditing ? deleteFile : nil)
                    .onMove(perform: editMode.isEditing ? moveFile : nil)
                }
                .id(editMode.isEditing)
                .scrollDisabled(true)
                .frame(height: CGFloat(120 + album.tracklist.count * 62))
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
                    if editMode.isEditing || isEditingName || isEditingArtists {
                        Button(action: {
                            if editMode.isEditing {
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
                                isEditingArtists = true;
                            }) {
                                Label("Edit Artists", systemImage: "pencil")
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
                        let resizedArtwork = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 600, height: 600))
                        let resizedArtworkSmall = Utils.shared.resizeImage(image: newArtwork, newSize: CGSize(width: 100, height: 100))
                        album.artwork = nil
                        album.smallArtwork = nil
                        let tuple = Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: album.directory)
                        album.artwork = tuple.first
                        album.smallArtwork = tuple.last
                        AlbumManager.shared.replaceAlbum(album)
                    }
            }
            .sheet(item: $trackToAdd) { track in
                AddToPlaylistView(showPopup: $showPopup, track: track)
            }
            .sheet(isPresented: $isFilePickerImagesPresented) {
                ImageDocumentPicker(imageURL: $artworkUrl)
                    .onDisappear {
                        do {
                            if let url = artworkUrl {
                                guard url.startAccessingSecurityScopedResource() else { return }
                                if let imageData = try? Data(contentsOf: url),
                                    let image = UIImage(data: imageData) {
                                
                                    let resizedArtwork = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 600, height: 600))
                                    let resizedArtworkSmall = Utils.shared.resizeImage(image: image, newSize: CGSize(width: 100, height: 100))
                                    album.artwork = nil
                                    album.smallArtwork = nil
                                    let tuple = Utils.shared.copyImagesToDocuments(artwork: resizedArtwork, smallArtwork: resizedArtworkSmall, directory: album.directory)
                                    album.artwork = tuple.first
                                    album.smallArtwork = tuple.last
                                    AlbumManager.shared.replaceAlbum(album)
                                }
                                url.stopAccessingSecurityScopedResource()
                            }
                        } catch {
                            print("File selection error: \(error.localizedDescription)")
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
    }
    
    private func deleteFile(at offsets: IndexSet) {
        markedForDeletion.append(album.tracklist[offsets.first!])
        album.tracklist.remove(atOffsets: offsets)
    }
    
    private func confirmChanges() {
        deleteFilesFromDocuments(filePaths: markedForDeletion.map { $0.path })
        AlbumManager.shared.replaceAlbum(album)
        editMode = .inactive
    }
    
    private func confirmNameChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditingName = false
    }
    
    private func confirmArtistsChanges() {
        album.artist = newArtist
        for i in 0..<album.tracklist.count {
            album.tracklist[i].artist = newArtist
        }
        AlbumManager.shared.replaceAlbum(album)
        isEditingArtists = false
    }
    
    private func confirmTrackChanges() {
        AlbumManager.shared.replaceAlbum(album)
        editingTrackIndex = nil
    }

    private func moveFile(from source: IndexSet, to destination: Int) {
        album.tracklist.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteFilesFromDocuments(filePaths: [String]) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for path in filePaths {
            do {
                let trackPath = documentsURL.appendingPathComponent(path)
                if fileManager.fileExists(atPath: trackPath.path) {
                    try fileManager.removeItem(at: trackPath)
                }
            } catch {
                print("Failed to delete file at path: \(path)")
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
            album.tracklist.append(contentsOf: newTracks)
            AlbumManager.shared.replaceAlbum(album)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}
