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
    @State var currentIds: Set<UUID> = []
    @State private var selectedIds = Set<UUID>()
    @State private var allTracks: [Track] = []
    @State private var searchText = ""
    
    var filteredTracks: [Track] {
        searchText.isEmpty ? allTracks : allTracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(filteredTracks, id: \.self) { track in
                        Button(action: {
                            let haptics = UISelectionFeedbackGenerator()
                            if selectedIds.contains(track.id) {
                                selectedIds.remove(track.id)
                            }
                            else {
                                selectedIds.insert(track.id)
                            }
                            haptics.selectionChanged()
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
                                if selectedIds.contains(track.id) {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                                else {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)
                                }
                            }
                        }
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
                    selectedTracks = allTracks.filter { selectedIds.contains($0.id) }
                    isPresented = false
                }
                .foregroundColor(.blue)
            )
            .onAppear {
                let albums: [Album] = AlbumManager.shared.fetchAlbums()
                let looseTracks = TrackManager.shared.fetchTracks()
                for track in looseTracks {
                    if !currentIds.contains(track.id) {
                        allTracks.append(track)
                    }
                }
                for album in albums {
                    var result: [Track] = []
                    for track in album.tracklist {
                        if !currentIds.contains(track.id) {
                            result.append(track)
                        }
                    }
                    allTracks.append(contentsOf: result)
                }
                for track in selectedTracks {
                    selectedIds.insert(track.id)
                }
            }
        }
    }
}
