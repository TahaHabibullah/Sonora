//
//  Library.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct LibraryView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @State private var isAddAlbumPresented = false
    @State private var isAddTracksPresented = false
    @State private var isFilePickerPresented = false
    @State private var showDeleteConfirmation = false
    @State private var showPopup: String = ""
    @State private var selectedFiles: [URL] = []
    @State private var albums: [Album] = []
    @State private var looseTracks: [Track] = []
    @State private var allTracks: [Track] = []
    @State private var albumResults: [Album] = []
    @State private var trackResults: [Track] = []
    @State private var trackToEdit: Track? = nil
    @State private var trackToDelete: Track? = nil
    @State private var trackToAdd: Track? = nil
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var sortOptionAlbum: SortOption = .recentPlayed
    @State private var sortOptionLooseTracks: SortOption = .firstAdded
    let haptics = UIImpactFeedbackGenerator(style: .light)
    
    enum SortOption {
        case recentPlayed, firstAdded, recentAdded, nameAsc, nameDesc, artistAsc, artistDesc
    }
    
    var sortedAlbums: [Album] {
        switch sortOptionAlbum {
        case .recentPlayed:
            return albums.sorted {
                guard let date0 = $0.lastPlayed, let date1 = $1.lastPlayed else {
                    return $0.lastPlayed != nil
                }
                return date0 > date1
            }
        case .firstAdded:
            return albums
        case .recentAdded:
            return albums.sorted { $0.dateAdded > $1.dateAdded }
        case .nameAsc:
            return albums.sorted { $0.name.uppercased() < $1.name.uppercased() }
        case .nameDesc:
            return albums.sorted { $0.name.uppercased() > $1.name.uppercased() }
        case .artistAsc:
            return albums.sorted { $0.artist.uppercased() < $1.artist.uppercased() }
        case .artistDesc:
            return albums.sorted { $0.artist.uppercased() > $1.artist.uppercased() }
        }
    }
    
    var sortedLooseTracks: [Track] {
        switch sortOptionLooseTracks {
        case .recentPlayed:
            return looseTracks
        case .firstAdded:
            return looseTracks
        case .recentAdded:
            return looseTracks
        case .nameAsc:
            return looseTracks.sorted { $0.title.uppercased() < $1.title.uppercased() }
        case .nameDesc:
            return looseTracks.sorted { $0.title.uppercased() > $1.title.uppercased() }
        case .artistAsc:
            return looseTracks.sorted { $0.artist.uppercased() < $1.artist.uppercased() }
        case .artistDesc:
            return looseTracks.sorted { $0.artist.uppercased() > $1.artist.uppercased() }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let gridItemSize = (screenWidth - 48) / 2
        
        NavigationStack {
            SearchLibraryView(isPresented: $isSearching,
                              albumResults: $albumResults,
                              trackResults: $trackResults)
                .searchable(text: $searchText, prompt: "Search in Library")
                .onChange(of: searchText, perform: { text in
                    albumResults = searchText.isEmpty ? [] : sortedAlbums.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    trackResults = searchText.isEmpty ? [] : allTracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                })
            
            if !isSearching {
                Picker(selection: $selectedTab, label: Text("")) {
                    Text("Albums").tag(0)
                    Text("Loose Tracks").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedTab) { _ in
                    haptics.impactOccurred()
                }
            }
                
            VStack {
                if isSearching {
                    
                }
                else if selectedTab == 0 {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sortedAlbums) { album in
                                NavigationLink(destination: AlbumView(album: album)) {
                                    VStack(spacing: 0) {
                                        if let artwork = Utils.shared.loadImageFromDocuments(filePath: album.artwork) {
                                            Image(uiImage: artwork)
                                                .resizable()
                                                .scaledToFit()
                                                .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                                .animation(nil)
                                        } else {
                                            Image(systemName: "music.note.list")
                                                .font(.title)
                                                .frame(width: gridItemSize, height: gridItemSize)
                                                .background(Color.black)
                                                .foregroundColor(.gray)
                                                .border(.gray, width: 1)
                                                .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                                .animation(nil)
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
                                            if !album.artist.isEmpty {
                                                Text(album.artist)
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
                        .padding(.bottom, 50)
                    }
                }
                
                else if selectedTab == 1 {
                    ScrollView {
                        LazyVStack {
                            ForEach(sortedLooseTracks) { track in
                                Button(action: {
                                    playQueue.startShuffledQueue(from: track, tracks: looseTracks, playlistName: "Loose Tracks")
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
                                                Text(track.artist)
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
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
                                                Label("Edit Details", systemImage: "pencil")
                                            }
                                            Button(role: .destructive, action: {
                                                trackToDelete = track
                                                showDeleteConfirmation = true
                                            }) {
                                                Label("Delete Track", systemImage: "trash")
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "ellipsis")
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 35, height: 50)
                                            .padding(.trailing, 15)
                                        }
                                        .contentShape(Rectangle())
                                        .simultaneousGesture(TapGesture().onEnded {
                                            haptics.impactOccurred()
                                        })
                                        .confirmationDialog("Are you sure you want to delete this track?",
                                                            isPresented: $showDeleteConfirmation,
                                                            titleVisibility: .visible) {
                                            Button("Delete", role: .destructive) {
                                                TrackManager.shared.deleteLooseTrack(trackToDelete!)
                                                looseTracks = TrackManager.shared.fetchTracks(key: "Loose_Tracks")
                                                trackToDelete = nil
                                                showDeleteConfirmation = false
                                            }
                                            Button("Cancel", role: .cancel) {
                                                showDeleteConfirmation = false
                                            }
                                        }
                                    }
                                    .frame(height: 65)
                                    .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                albums = AlbumManager.shared.fetchAlbums()
                looseTracks = TrackManager.shared.fetchTracks(key: "Loose_Tracks")
                allTracks = TrackManager.shared.fetchAllTracks()
            }
            .navigationTitle("Library")
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(action: {
                                sortOptionAlbum = .recentPlayed
                            }) {
                                HStack {
                                    Text("Recently Played")
                                    Spacer()
                                    if sortOptionAlbum == .recentPlayed {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .firstAdded
                            }) {
                                HStack {
                                    Text("First Added")
                                    Spacer()
                                    if sortOptionAlbum == .firstAdded {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .recentAdded
                            }) {
                                HStack {
                                    Text("Recently Added")
                                    Spacer()
                                    if sortOptionAlbum == .recentAdded {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .nameAsc
                            }) {
                                HStack {
                                    Text("Name A-Z")
                                    Spacer()
                                    if sortOptionAlbum == .nameAsc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .nameDesc
                            }) {
                                HStack {
                                    Text("Name Z-A")
                                    Spacer()
                                    if sortOptionAlbum == .nameDesc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .artistAsc
                            }) {
                                HStack {
                                    Text("Artist A-Z")
                                    Spacer()
                                    if sortOptionAlbum == .artistAsc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionAlbum = .artistDesc
                            }) {
                                HStack {
                                    Text("Artist Z-A")
                                    Spacer()
                                    if sortOptionAlbum == .artistDesc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            haptics.impactOccurred()
                        })
                    }
                }
                else if selectedTab == 1 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(action: {
                                sortOptionLooseTracks = .firstAdded
                            }) {
                                HStack {
                                    Text("First Added")
                                    Spacer()
                                    if sortOptionLooseTracks == .firstAdded {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionLooseTracks = .nameAsc
                            }) {
                                HStack {
                                    Text("Title A-Z")
                                    Spacer()
                                    if sortOptionLooseTracks == .nameAsc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionLooseTracks = .nameDesc
                            }) {
                                HStack {
                                    Text("Title Z-A")
                                    Spacer()
                                    if sortOptionAlbum == .nameDesc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionLooseTracks = .artistAsc
                            }) {
                                HStack {
                                    Text("Artist A-Z")
                                    Spacer()
                                    if sortOptionLooseTracks == .artistAsc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOptionLooseTracks = .artistDesc
                            }) {
                                HStack {
                                    Text("Artist Z-A")
                                    Spacer()
                                    if sortOptionLooseTracks == .artistDesc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            haptics.impactOccurred()
                        })
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            isAddAlbumPresented = true
                        }) {
                            Label("Create New Album", systemImage: "rectangle.stack.badge.plus")
                        }
                        
                        Button(action: {
                            isFilePickerPresented = true
                        }) {
                            Label("Import Loose Tracks", systemImage: "music.note")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            .font(.title2)
                        }
                        .foregroundColor(.blue)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        haptics.impactOccurred()
                    })
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
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                handleFileSelection(result: result)
                isAddTracksPresented = true
            }
            .sheet(isPresented: $isAddAlbumPresented) {
                AddAlbumView(isPresented: $isAddAlbumPresented, showPopup: $showPopup)
                    .onDisappear {
                        albums = AlbumManager.shared.fetchAlbums()
                    }
            }
            .sheet(isPresented: $isAddTracksPresented) {
                AddTracksView(isPresented: $isAddTracksPresented, showPopup: $showPopup, selectedFiles: selectedFiles)
                    .onDisappear {
                        looseTracks = TrackManager.shared.fetchTracks(key: "Loose_Tracks")
                        selectedFiles.removeAll()
                    }
            }
            .sheet(item: $trackToEdit) { track in
                EditTrackView(track: track)
                    .onDisappear {
                        looseTracks = TrackManager.shared.fetchTracks(key: "Loose_Tracks")
                        if let index = looseTracks.firstIndex(where: { $0.id == track.id }) {
                            let artwork = looseTracks[index].artwork
                            let smallArtwork = looseTracks[index].smallArtwork
                            looseTracks[index].artwork = ""
                            looseTracks[index].smallArtwork = ""
                            looseTracks[index].artwork = artwork
                            looseTracks[index].smallArtwork = smallArtwork
                        }
                    }
            }
            .sheet(item: $trackToAdd) { track in
                AddToPlaylistView(showPopup: $showPopup, track: track)
            }
        }
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
}
