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
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                        .padding()
                }
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                            .frame(width: 40, height: 5)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    Text(playQueue.name)
                        .font(.headline)
                        .bold()
                        .padding()
                }
                Spacer()
                Text("")
                    .frame(width: 20)
                    .padding()
            }
            
            if let currentIndex = playQueue.currentIndex {
                HStack {
                    Text("Now Playing")
                        .font(.headline)
                        .bold()
                    Spacer()
                }
                .padding(.leading, 15)
                
                HStack {
                    if let artwork = playQueue.artworks[currentIndex] {
                        Image(uiImage: UIImage(data: artwork)!)
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
                            Text(playQueue.titles[currentIndex])
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                        }
                        HStack {
                            Text(playQueue.artists[currentIndex])
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                
                HStack {
                    Text("Next In Queue:")
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
                        .disabled(playQueue.currentIndex == nil)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                
                List {
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
                .background(.black)
                .padding(.bottom, 50)
                .listStyle(PlainListStyle())
                
            }
            else {
                Text("-")
                    .font(.headline)
                    .bold()
                    .padding()
                
                Text("Not Playing")
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .edgesIgnoringSafeArea(.all)
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
