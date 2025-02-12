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
    let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack {
            if let currentTrack = playQueue.currentTrack {
                if let artwork = Utils.shared.loadImageFromDocuments(filePath: currentTrack.artwork) {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                else {
                    Image(systemName: "music.note.list")
                        .font(.subheadline)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.5))
                }
                
                Text(currentTrack.title)
                    .padding(.leading, 10)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            else {
                Image(systemName: "music.note.list")
                    .font(.subheadline)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.5))
                
                Text("Not Playing")
                    .padding(.leading, 10)
                    .font(.headline)
            }
            Spacer()
            Button(action: {
                haptics.impactOccurred()
                playQueue.prevTrack()
            }) {
                Image(systemName: "backward.fill")
                    .font(.headline)
            }
            .padding(.trailing, 10)
            if playQueue.isPlaying {
                Button(action: {
                    haptics.impactOccurred()
                    playQueue.pausePlayback()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                }
                .padding(.trailing, 10)
            }
            else {
                Button(action: {
                    haptics.impactOccurred()
                    playQueue.resumePlayback()
                }) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                }
                .padding(.trailing, 10)
            }
            Button(action: {
                haptics.impactOccurred()
                playQueue.skipTrack()
            }) {
                Image(systemName: "forward.fill")
                    .font(.headline)
            }
            .padding(.trailing, 20)
        }
        .frame(width: UIScreen.main.bounds.width, height: 50)
        .background(.ultraThinMaterial)
        .contentShape(Rectangle())
        .accentColor(.gray)
        .onTapGesture {
            isPlayerViewPresented = true
        }
        .sheet(isPresented: $isPlayerViewPresented) {
            PlayerView(isPresented: $isPlayerViewPresented)
                .background(.ultraThinMaterial)
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let controller = windowScene.windows.first?.rootViewController?.presentedViewController
                            else { return }
                    controller.view.backgroundColor = .clear
                }
        }
    }
}
