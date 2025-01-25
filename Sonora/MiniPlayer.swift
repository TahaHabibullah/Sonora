//
//  MiniPlayer.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject var playQueue: PlayQueue
    @State private var isPlayerViewPresented = false
    @State private var isHighlighted: Bool = false
    @State private var size: CGSize?

    var body: some View {
        HStack {
            if let currentIndex = playQueue.currentIndex {
                Text(playQueue.titles[currentIndex])
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
        .padding(.horizontal, 20)
        .frame(width: UIScreen.main.bounds.width, height: 50)
        .contentShape(Rectangle())
        .accentColor(.gray)
        .onTapGesture {
            isPlayerViewPresented = true
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -20 {
                        isPlayerViewPresented = true
                    }
                }
        )
        .sheet(isPresented: $isPlayerViewPresented) {
            PlayerView(isPresented: $isPlayerViewPresented)
        }
    }
}
