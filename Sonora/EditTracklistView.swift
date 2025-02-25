//
//  EditTracklistView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/9/25.
//

import SwiftUI

struct EditTracklistView: View {
    @Binding var isPresented: Bool
    @Binding var tracklist: [Track]
    @State var playlist: Playlist
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(tracklist, id: \.self) { track in
                        HStack {
                            if let artwork = Utils.shared.loadImageFromDocuments(filePath: track.smallArtwork) {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .animation(nil)
                            }
                            else {
                                Image(systemName: "music.note.list")
                                    .font(.subheadline)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.5))
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
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete(perform: deleteTrack)
                    .onMove(perform: moveTrack)
                }
                .listStyle(PlainListStyle())
            }
            .padding(.top, 5)
            .navigationTitle("Edit Tracklist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.blue),
                trailing: Button("Save") {
                    PlaylistManager.shared.replacePlaylist(playlist)
                    isPresented = false
                }
                .foregroundColor(.blue)
            )
        }
    }
    
    private func deleteTrack(at offsets: IndexSet) {
        playlist.tracklist.remove(atOffsets: offsets)
        tracklist.remove(atOffsets: offsets)
    }

    private func moveTrack(from source: IndexSet, to destination: Int) {
        playlist.tracklist.move(fromOffsets: source, toOffset: destination)
        tracklist.move(fromOffsets: source, toOffset: destination)
    }
}
