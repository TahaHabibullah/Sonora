//
//  Playlists.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI

struct PlaylistsView: View {
    @State private var isAddPlaylistPresented: Bool = false
    @State private var playlists: [Playlist] = []
    
    var body: some View {
        VStack {
            NavigationStack {
                VStack {
                    List {
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                                HStack() {
                                    if let artwork = playlist.artwork {
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
                                    if !playlist.name.isEmpty {
                                        Text(playlist.name)
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
                                            .font(.subheadline)
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
                .onAppear {
                    playlists = PlaylistManager.shared.fetchPlaylists()
                }
                .navigationTitle("Playlists")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddPlaylistPresented = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                .font(.title2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(isPresented: $isAddPlaylistPresented) {
                    AddPlaylistView(isPresented: $isAddPlaylistPresented)
                        .onDisappear {
                            playlists = PlaylistManager.shared.fetchPlaylists()
                        }
                }
            }
        }
    }
}
