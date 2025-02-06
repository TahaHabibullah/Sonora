//
//  TrackPickerView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/5/25.
//

import SwiftUI

struct TrackPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTracks: [Track]
    @State private var selectedIds = Set<UUID>()
    @State private var allTracks: [Track] = []
    @State private var searchText = ""
    @State private var preloadedImages: [String?: UIImage?] = [:]
    let albums: [Album] = AlbumManager.shared.fetchAlbums()
    
    var filteredTracks: [Track] {
        searchText.isEmpty ? allTracks : allTracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(filteredTracks, id: \.self) { track in
                        Button(action: {
                            if selectedIds.contains(track.id) {
                                selectedIds.remove(track.id)
                            }
                            else {
                                selectedIds.insert(track.id)
                            }
                        }) {
                            HStack {
                                if let artworkPath = track.artwork {
                                    if let artwork = preloadedImages[artworkPath]! {
                                        Image(uiImage: artwork)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
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
                            }
                        }
                        .listRowBackground(selectedIds.contains(track.id) ? Color.blue.opacity(0.1) : Color.clear)
                    }
                }
                .searchable(text: $searchText, prompt: "Search Tracks")
                .listStyle(PlainListStyle())
            }
            .navigationTitle(selectedIds.isEmpty ? "All Tracks" : "\(selectedIds.count) Tracks Selected")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.blue),
                trailing: Button("Done") {
                    selectedTracks.append(contentsOf: allTracks.filter { selectedIds.contains($0.id) })
                    isPresented = false
                }
                .foregroundColor(.blue)
            )
            .onAppear {
                let looseTracks = TrackManager.shared.fetchTracks()
                allTracks.append(contentsOf: looseTracks)
                for album in albums {
                    let trackList = AlbumManager.shared.convertToTrackList(album)
                    let artwork = Utils.shared.loadImageFromDocuments(filePath: album.artwork)
                    allTracks.append(contentsOf: trackList)
                    preloadedImages[album.artwork] = Utils.shared.resizeImageSmall(image: artwork)
                }
                
                for track in looseTracks {
                    let artwork = Utils.shared.loadImageFromDocuments(filePath: track.artwork)
                    preloadedImages[track.artwork] = Utils.shared.resizeImageSmall(image: artwork)
                }
            }
        }
    }
}
