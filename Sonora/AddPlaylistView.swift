//
//  AddPlaylistView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/5/25.
//

import SwiftUI
import AVFoundation

struct AddPlaylistView: View {
    @Binding var isPresented: Bool
    @Binding var showPopup: String
    @State private var artwork: UIImage? = nil
    @State private var playlistName: String = ""
    @State private var isImagePickerPresented = false
    @State private var isTrackPickerPresented = false
    @State var selectedTracks: [Track] = []
    
    var body: some View {
        NavigationView {
            GeometryReader { _ in
                ScrollView {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isImagePickerPresented = true
                    }) {
                        ZStack {
                            if let artwork = artwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                            }
                            else {
                                Image(systemName: "music.note.list")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(Color.gray.opacity(0.5))
                            }
                            
                            VStack {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.subheadline)
                                        .foregroundColor(Color.black.opacity(0.5))
                                }
                                .frame(width: 40, height: 40)
                                .background(.gray)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.5), radius: 5)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("Playlist Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        TextField("", text: $playlistName)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray),
                                alignment: .bottom
                            )
                    }
                    .padding([.leading, .trailing])
                    .padding(.top, 10)
                    
                    List {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isTrackPickerPresented = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Add Tracks")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        ForEach(selectedTracks, id: \.self) { track in
                            HStack {
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
                                Text(Utils.shared.getTrackDuration(from: track.path))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                            }
                            .frame(height: 40)
                        }
                        .onDelete(perform: deleteTrack)
                        .onMove(perform: moveTrack)
                    }
                    .padding(.top, 10)
                    .frame(height: CGFloat(120 + selectedTracks.count * 62))
                    .listStyle(PlainListStyle())
                    .scrollDisabled(true)
                }
                .navigationTitle("New Playlist")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue),
                    trailing: Button("Save") {
                        let resizedArtwork = Utils.shared.resizeImage(image: artwork, newSize: CGSize(width: 400, height: 400))
                        let playlist = Playlist(name: playlistName, artwork: resizedArtwork, tracklist: selectedTracks)
                        PlaylistManager.shared.savePlaylist(playlist)
                        showPopup = "Created playlist"
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $artwork)
        }
        .sheet(isPresented: $isTrackPickerPresented) {
            TrackPickerView(isPresented: $isTrackPickerPresented, selectedTracks: $selectedTracks)
        }
    }
    
    private func deleteTrack(at offset: IndexSet) {
        selectedTracks.remove(atOffsets: offset)
    }
    
    private func moveTrack(from source: IndexSet, to destination: Int) {
        selectedTracks.move(fromOffsets: source, toOffset: destination)
    }
}
