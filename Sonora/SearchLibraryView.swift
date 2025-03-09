//
//  SearchLibraryView.swift
//  Sonora
//
//  Created by Taha Habibullah on 3/7/25.
//
import SwiftUI

struct SearchLibraryView: View {
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject var playQueue: PlayQueue
    @Binding var isPresented: Bool
    @Binding var albumResults: [Album]
    @Binding var trackResults: [Track]
    @State var showPopup: String = ""
    @State private var trackToEdit: Track? = nil
    @State private var trackToAdd: Track? = nil
    let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            if isSearching {
                VStack {
                    List {
                        ForEach(albumResults) { album in
                            NavigationLink(destination: AlbumView(album: album)) {
                                HStack {
                                    if let artwork = Utils.shared.loadImageFromDocuments(filePath: album.smallArtwork) {
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
                                            Text(album.name)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                        }
                                        HStack {
                                            if !album.artist.isEmpty {
                                                Text("\(album.artist) | Album")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            else {
                                                Text("Unknown Artist | Album")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        
                        ForEach(trackResults, id: \.self) { track in
                            Button(action: {
                                playQueue.playSingleTrack(track: track)
                            }) {
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
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                        }
                                        HStack {
                                            if !track.artist.isEmpty {
                                                Text("\(track.artist) | Track")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            else {
                                                Text("Unknown Artist | Track")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            Spacer()
                                        }
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
                                            playQueue.prependToQueue(track)
                                            withAnimation(.linear(duration: 0.25)) {
                                                showPopup = "Added to queue"
                                            }
                                        }) {
                                            Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                                        }
                                        if !playQueue.trackQueue.isEmpty {
                                            Button(action: {
                                                playQueue.appendToQueue(track)
                                                withAnimation(.linear(duration: 0.25)) {
                                                    showPopup = "Added to queue"
                                                }
                                            }) {
                                                Label("Add To Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
                                            }
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
                .sheet(item: $trackToAdd) { track in
                    AddToPlaylistView(showPopup: $showPopup, track: track)
                }
                .sheet(item: $trackToEdit) { track in
                    EditTrackView(track: track)
                        .onDisappear {
                            if let index = trackResults.firstIndex(where: { $0.id == track.id }) {
                                let allTracks = TrackManager.shared.fetchAllTracks()
                                let updatedTrack = allTracks.filter { $0.id == track.id }.first!
                                trackResults[index] = updatedTrack
                                let artwork = trackResults[index].artwork
                                let smallArtwork = trackResults[index].smallArtwork
                                trackResults[index].artwork = ""
                                trackResults[index].smallArtwork = ""
                                trackResults[index].artwork = artwork
                                trackResults[index].smallArtwork = smallArtwork
                            }
                        }
                }
            }
        }
        .onChange(of: isSearching, perform: { newValue in
            if newValue {
                isPresented = newValue
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPresented = newValue
                }
            }
        })
    }
}
