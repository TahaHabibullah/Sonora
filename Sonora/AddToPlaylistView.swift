//
//  AddToPlaylistView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/8/25.
//

import SwiftUI

struct AddToPlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var showPopup: String
    @State var track: Track
    @State var playlists: [Playlist] = []
    @State private var isAddPlaylistPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Button(action: {
                        isAddPlaylistPresented = true
                    }) {
                        HStack() {
                            Image(systemName: "plus")
                                .font(.title)
                                .frame(width: 75, height: 75)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Text("Create New Playlist")
                                .padding(.leading, 10)
                                .foregroundColor(.white)
                                .font(.title3)
                                .bold()
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    ForEach(Array(playlists.enumerated()), id:\.element) { index, element in
                        Button(action: {
                            var playlist = playlists[index]
                            playlist.tracklist.append(track.id)
                            let tracklist = TrackManager.shared.fetchPlaylist(from: playlist.tracklist)
                            playlist.duration = Utils.shared.getPlaylistDuration(from: tracklist.map { $0.path })
                            PlaylistManager.shared.replacePlaylist(playlist)
                            showPopup = "Added to playlist"
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack() {
                                if let artwork = element.artwork {
                                    Image(uiImage: UIImage(data: artwork)!)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 75, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Image(systemName: "music.note.list")
                                        .font(.title)
                                        .frame(width: 75, height: 75)
                                        .background(Color.black)
                                        .foregroundColor(.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                if !element.name.isEmpty {
                                    Text(element.name)
                                        .padding(.leading, 10)
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .bold()
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                else {
                                    Text("Untitled playlist")
                                        .padding(.leading, 10)
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .bold()
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(Text("Add To Playlist"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            )
        }
        .onAppear {
            playlists = PlaylistManager.shared.fetchPlaylists()
            for playlist in playlists {
                let idSet = Set(playlist.tracklist)
                if idSet.contains(track.id) {
                    playlists.removeAll { $0.id == playlist.id }
                }
            }
        }
        .sheet(isPresented: $isAddPlaylistPresented) {
            AddPlaylistView(isPresented: $isAddPlaylistPresented, showPopup: $showPopup, selectedTracks: [track])
                .onDisappear {
                    if showPopup == "Created playlist" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        }
    }
}
