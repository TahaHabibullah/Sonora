//
//  MiniPlayer.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject var playQueue: PlayQueue

    var body: some View {
        let currentIndex = playQueue.currentIndex
        HStack {
            if currentIndex != nil {
                Text(playQueue.tracks[currentIndex!]
                    .deletingPathExtension().lastPathComponent)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
            }
            else {
                Text("Not Playing")
                    .font(.headline)
            }
            Spacer()
            Button(action: playQueue.prevTrack) {
                Image(systemName: "backward.fill")
                    .font(.headline)
            }
            if playQueue.isPlaying {
                Button(action: playQueue.pausePlayback) {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                }
            }
            else {
                Button(action: playQueue.resumePlayback) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                }
            }
            Button(action: playQueue.skipTrack) {
                Image(systemName: "forward.fill")
                    .font(.headline)
            }
        }
        .padding(.bottom, 8)
        .accentColor(.gray)
    }
}
