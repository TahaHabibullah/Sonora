//
//  QueueView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/31/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct QueueView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                        .padding()
                }
                Spacer()
                Text(playQueue.name)
                    .font(.headline)
                    .bold()
                    .padding()
                Spacer()
                Text("")
                    .frame(width: 20)
                    .padding()
            }
            
                if let currentIndex = playQueue.currentIndex,
                    let currentTrack = playQueue.currentTrack {
                    HStack {
                        Text("Now Playing")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }
                    .padding(.leading, 15)
                    
                    HStack {
                        if let artwork = Utils.shared.loadImageFromDocuments(
                            filePath: currentTrack.artwork) {
                            Image(uiImage: artwork)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding()
                        }
                        else {
                            Image(systemName: "music.note.list")
                                .font(.subheadline)
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.5))
                                .padding()
                        }
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text(currentTrack.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                            HStack {
                                Text(currentTrack.artist)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    
                    List {
                        if !playQueue.trackQueue.isEmpty {
                            Section {
                                ForEach(Array(playQueue.trackQueue.enumerated()), id: \.element) { index, element in
                                    Button(action: {
                                        playQueue.skipQueueToTrack(index)
                                    }) {
                                        HStack {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    Text(element.title)
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text(element.artist)
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
                                    .listRowBackground(Color.black)
                                    .padding(.horizontal, 0)
                                    .padding(.vertical, 10)
                                }
                                .onDelete(perform: deleteQueueTrack)
                                .onMove(perform: moveQueueTrack)
                                
                            } header: {
                                HStack {
                                    Text("Next In Queue:")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .bold()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .background(Color.black)
                            }
                        }
                        
                        Section {
                            if !playQueue.tracks.isEmpty {
                                ForEach(Array(playQueue.tracks[(currentIndex+1)...].enumerated()), id: \.element) { index, element in
                                    Button(action: {
                                        playQueue.skipToTrack(currentIndex+1 + index)
                                    }) {
                                        HStack {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    Text(playQueue.titles[currentIndex+1 + index])
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text(playQueue.artists[currentIndex+1 + index])
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
                                    .listRowBackground(Color.black)
                                    .padding(.horizontal, 0)
                                    .padding(.vertical, 10)
                                }
                                .onDelete(perform: deleteTrack)
                                .onMove(perform: moveTrack)
                            }
                        } header: {
                            if !playQueue.tracks.isEmpty {
                                HStack {
                                    Text("Next From \(playQueue.originalName):")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .bold()
                                    Spacer()
                                    if playQueue.isShuffled {
                                        Button(action: {
                                            playQueue.unshuffleTracks()
                                        }) {
                                            Image(systemName: "shuffle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.blue)
                                        }
                                        .disabled(playQueue.currentIndex == nil)
                                    }
                                    else {
                                        Button(action: {
                                            playQueue.shuffleTracks()
                                        }) {
                                            Image(systemName: "shuffle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.gray)
                                        }
                                        .disabled(playQueue.tracks.isEmpty)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .background(Color.black)
                            }
                        }
                    }
                    .padding(.top, -25)
                    .listStyle(PlainListStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 20)
        .background(.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func deleteQueueTrack(at offsets: IndexSet) {
        playQueue.trackQueue.remove(atOffsets: offsets)
    }

    private func moveQueueTrack(from source: IndexSet, to destination: Int) {
        playQueue.trackQueue.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteTrack(at offsets: IndexSet) {
        if let index = offsets.first {
            if let currentIndex = playQueue.currentIndex {
                playQueue.tracks.remove(at: index + currentIndex+1)
                playQueue.titles.remove(at: index + currentIndex+1)
            }
        }
    }
    
    private func moveTrack(from source: IndexSet, to destination: Int) {
        var indexOffset: IndexSet = []
        if let index = source.first {
            if let currentIndex = playQueue.currentIndex {
                indexOffset.insert(index + currentIndex+1)
                playQueue.tracks.move(fromOffsets: indexOffset, toOffset: destination + currentIndex+1)
                playQueue.titles.move(fromOffsets: indexOffset, toOffset: destination + currentIndex+1)
            }
        }
    }
}
