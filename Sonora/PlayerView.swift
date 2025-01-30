//
//  PlayerView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI
import UIKit
import AVFoundation
import MediaPlayer

struct PlayerView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @Binding var isPresented: Bool
    @State private var sliderValue: Double = 0.0
    @State private var timer: Timer?
    @State private var isEditing: Bool = false
    
    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        let imageSize: CGFloat = screenHeight > 812 ? 300 : screenHeight > 736 ? 250 : 200
        VStack(spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                Spacer()
            }
            
            if let currentIndex = playQueue.currentIndex {
                Text(playQueue.name)
                    .font(.headline)
                    .bold()
                    .padding()
                
                if let artwork = playQueue.artworks[currentIndex] {
                    Image(uiImage: UIImage(data: artwork)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                        .shadow(color: .black, radius: 10)
                }
                else {
                    Image(systemName: "music.note.list")
                        .font(.title)
                        .frame(width: imageSize, height: imageSize)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack {
                    Text(playQueue.titles[currentIndex])
                        .font(.title2)
                        .bold()
                    
                    Text(playQueue.artists[currentIndex])
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            else {
                Text("-")
                    .font(.headline)
                    .bold()
                    .padding()
                
                Image(systemName: "music.note.list")
                    .font(.title)
                    .frame(width: imageSize, height: imageSize)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack {
                    Text("Not Playing")
                        .font(.title2)
                        .bold()
                    
                    Text("-")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
            }

            VStack(spacing: 0) {
                Slider(value: $sliderValue, in: 0...1, step: 0.01, onEditingChanged: { editing in
                    isEditing = editing
                    if !editing {
                        playQueue.audioPlayer?.currentTime = sliderValue * playQueue.audioPlayer!.duration
                    }
                })
                .padding()
                .frame(height: 30)
                .accentColor(.white)
                
                HStack {
                    if let duration = playQueue.audioPlayer?.duration {
                        Text(formatTime(sliderValue * duration))
                            .font(.subheadline)
                        Spacer()
                        Text("-" + formatTime(duration - sliderValue * duration))
                            .font(.subheadline)
                    }
                    else {
                        Text("--:--")
                            .font(.subheadline)
                        Spacer()
                        Text("--:--")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.top, 30)

            HStack {
                Button(action: playQueue.prevTrack) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.white)
                        .padding()
                }
                if playQueue.isPlaying {
                    Button(action: playQueue.pausePlayback) {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                else {
                    Button(action: playQueue.resumePlayback) {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Button(action: playQueue.skipTrack) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding(.top, 30)
            
            HStack(alignment: .top) {
                Image(systemName: "speaker.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(.top, 5)
                VolumeSlider()
                    .accentColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                Image(systemName: "speaker.wave.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .padding(.top, 20)
        }
        .onAppear {
            UISlider.appearance().setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
            if playQueue.currentIndex != nil {
                startTimer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .padding()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let playQueue = playQueue.audioPlayer, !isEditing else { return }
            sliderValue = playQueue.currentTime / playQueue.duration
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%2d:%02d", minutes, seconds)
    }
}

struct VolumeSlider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MPVolumeViewController {
        return MPVolumeViewController()
    }

    func updateUIViewController(_ uiViewController: MPVolumeViewController, context: Context) {
    }
}

class MPVolumeViewController: UIViewController {
    private var volumeView: MPVolumeView!

    override func viewDidLoad() {
        super.viewDidLoad()

        volumeView = MPVolumeView(frame: self.view.bounds)
        volumeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        volumeView.showsRouteButton = false
        self.view.addSubview(volumeView)
    }
}
