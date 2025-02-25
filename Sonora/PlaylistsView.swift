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
    @State private var showPopup: String = ""
    @State private var sortOption: SortOption = .recentPlayed
    let haptics = UIImpactFeedbackGenerator(style: .light)
    
    enum SortOption {
        case recentPlayed, recentAdded, nameAsc, nameDesc
    }
    
    var sortedItems: [Playlist] {
        switch sortOption {
        case .recentPlayed:
            return playlists.sorted {
                guard let date0 = $0.lastPlayed, let date1 = $1.lastPlayed else {
                    return $0.lastPlayed != nil
                }
                return date0 > date1
            }
        case .recentAdded:
            return playlists.sorted { $0.dateAdded > $1.dateAdded }
        case .nameAsc:
            return playlists.sorted { $0.name.uppercased() < $1.name.uppercased() }
        case .nameDesc:
            return playlists.sorted { $0.name.uppercased() > $1.name.uppercased() }
        }
    }
    
    var body: some View {
        VStack {
            NavigationStack {
                VStack {
                    List {
                        ForEach(sortedItems) { playlist in
                            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                                HStack() {
                                    if let artwork = playlist.artwork {
                                        Image(uiImage: UIImage(data: artwork)!)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 75, height: 75)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .animation(nil)
                                    } else {
                                        Image(systemName: "music.note.list")
                                            .font(.title)
                                            .frame(width: 75, height: 75)
                                            .background(Color.black)
                                            .foregroundColor(.gray)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                .stroke(.gray, lineWidth: 1)
                                            )
                                            .animation(nil)
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
                    playlists = PlaylistManager.shared.fetchPlaylists()
                }
                .navigationTitle("Playlists")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(action: {
                                sortOption = .recentPlayed
                            }) {
                                HStack {
                                    Text("Recently Played")
                                    Spacer()
                                    if sortOption == .recentPlayed {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOption = .recentAdded
                            }) {
                                HStack {
                                    Text("Recently Added")
                                    Spacer()
                                    if sortOption == .recentAdded {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOption = .nameAsc
                            }) {
                                HStack {
                                    Text("Name A-Z")
                                    Spacer()
                                    if sortOption == .nameAsc {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: {
                                sortOption = .nameDesc
                            }) {
                                HStack {
                                    Text("Name Z-A")
                                    Spacer()
                                    if sortOption == .nameDesc {
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            haptics.impactOccurred()
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
                    AddPlaylistView(isPresented: $isAddPlaylistPresented, showPopup: $showPopup)
                        .onDisappear {
                            playlists = PlaylistManager.shared.fetchPlaylists()
                        }
                }
            }
        }
    }
}
