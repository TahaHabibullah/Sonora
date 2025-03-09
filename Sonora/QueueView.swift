//
//  QueueView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/31/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import MarqueeText

struct QueueView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @Binding var isPresented: Bool
    @State private var showConfirmationDialog: Bool = false
    let selectionHaptics = UISelectionFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    let haptics = UIImpactFeedbackGenerator(style: .light)
                    haptics.impactOccurred()
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
                MarqueeText(text: playQueue.name,
                            font: UIFont.preferredFont(forTextStyle: .headline),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 3,
                            alignment: .center)
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
                    if let artwork = Utils.shared.loadImageFromDocuments(filePath: currentTrack.smallArtwork) {
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
                        MarqueeText(text: currentTrack.title,
                                    font: UIFont.preferredFont(forTextStyle: .subheadline),
                                    leftFade: 16,
                                    rightFade: 16,
                                    startDelay: 3)
                        
                        MarqueeText(text: currentTrack.artist,
                                    font: UIFont.preferredFont(forTextStyle: .subheadline),
                                    leftFade: 16,
                                    rightFade: 16,
                                    startDelay: 3)
                                    .foregroundColor(.gray)
                    }
                    .padding(.leading, -10)
                    .padding(.trailing, 10)
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
                                Button(action: {
                                    showConfirmationDialog = true
                                }) {
                                    Text("Clear")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                            .background(Color.black)
                        }
                    }
                    
                    if !playQueue.tracklist.isEmpty {
                        Section {
                            ForEach(Array(playQueue.tracklist.dropFirst(currentIndex+1).prefix(50).enumerated()), id: \.element) { index, element in
                                Button(action: {
                                    playQueue.skipToTrack(currentIndex+1 + index)
                                }) {
                                    HStack {
                                        VStack(spacing: 0) {
                                            HStack {
                                                Text(playQueue.tracklist[currentIndex+1 + index].title)
                                                    .font(.subheadline)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Spacer()
                                            }
                                            HStack {
                                                Text(playQueue.tracklist[currentIndex+1 + index].artist)
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
                            
                        } header: {
                            HStack {
                                Text("Next From \(playQueue.originalName):")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .bold()
                                Spacer()
                                
                                if playQueue.isRepeatingQueue {
                                    Button(action: {
                                        selectionHaptics.selectionChanged()
                                        playQueue.isRepeatingTrack = true
                                        playQueue.isRepeatingQueue = false
                                        playQueue.replaceNextItem()
                                    }) {
                                        Image(systemName: "repeat")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(playQueue.currentTrack == nil)
                                }
                                else if playQueue.isRepeatingTrack {
                                    Button(action: {
                                        selectionHaptics.selectionChanged()
                                        playQueue.isRepeatingTrack = false
                                        playQueue.replaceNextItem()
                                    }) {
                                        Image(systemName: "repeat.1")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(playQueue.currentTrack == nil)
                                }
                                else {
                                    Button(action: {
                                        selectionHaptics.selectionChanged()
                                        playQueue.isRepeatingQueue = true
                                        playQueue.replaceNextItem()
                                    }) {
                                        Image(systemName: "repeat")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.gray)
                                    }
                                    .disabled(playQueue.currentTrack == nil)
                                }
                                
                                if playQueue.isShuffled {
                                    Button(action: {
                                        selectionHaptics.selectionChanged()
                                        playQueue.unshuffleTracks()
                                    }) {
                                        Image(systemName: "shuffle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.leading, 20)
                                    .disabled(playQueue.currentIndex == nil)
                                }
                                else {
                                    Button(action: {
                                        selectionHaptics.selectionChanged()
                                        playQueue.shuffleTracks()
                                    }) {
                                        Image(systemName: "shuffle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 20)
                                    .disabled(playQueue.tracklist.isEmpty)
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
            else {
                HStack {
                    Text("Not Playing")
                        .font(.headline)
                        .bold()
                    Spacer()
                }
                .padding(.leading, 15)
                
                HStack {
                    Image(systemName: "music.note.list")
                        .font(.subheadline)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.5))
                        .padding()
                    
                    Text("-")
                        .font(.subheadline)
                        .padding(.leading, -10)
                        .padding(.trailing, 10)
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Spacer()
            }
        }
        .confirmationDialog("Are you sure you want to clear the queue?",
                            isPresented: $showConfirmationDialog,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                playQueue.clearTrackQueue()
                showConfirmationDialog = false
            }
            Button("Cancel", role: .cancel) {
                showConfirmationDialog = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    private func deleteQueueTrack(at offsets: IndexSet) {
        playQueue.trackQueue.remove(atOffsets: offsets)
        if offsets.first == 0 {
            playQueue.replaceNextItem()
        }
    }

    private func moveQueueTrack(from source: IndexSet, to destination: Int) {
        playQueue.trackQueue.move(fromOffsets: source, toOffset: destination)
        if destination == 0 {
            playQueue.replaceNextItem()
        }
    }
    
    private func deleteTrack(at offsets: IndexSet) {
        if let index = offsets.first {
            if let currentIndex = playQueue.currentIndex {
                playQueue.tracklist.remove(at: index + currentIndex+1)
                if index == 0 {
                    playQueue.replaceNextItem()
                }
            }
        }
    }
    
    private func moveTrack(from source: IndexSet, to destination: Int) {
        var indexOffset: IndexSet = []
        if let index = source.first {
            if let currentIndex = playQueue.currentIndex {
                indexOffset.insert(index + currentIndex+1)
                playQueue.tracklist.move(fromOffsets: indexOffset, toOffset: destination + currentIndex+1)
                if destination == 0 {
                    playQueue.replaceNextItem()
                }
            }
        }
    }
}
