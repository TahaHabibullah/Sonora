//
//  PlayerView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import MarqueeText

struct PlayerView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @Binding var isPresented: Bool
    @State var isQueuePresented: Bool = false
    @State private var sliderValue: Double = 0.0
    @State private var isEditing: Bool = false
    @State private var isSeeking: Bool = false
    @State private var timer: Timer?
    let selectionHaptics = UISelectionFeedbackGenerator()
    let impactHaptics = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        let baseFont = UIFont.preferredFont(forTextStyle: .title2)
        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldFont = UIFont(descriptor: descriptor ?? baseFont.fontDescriptor, size: baseFont.pointSize)
        
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
                
                VStack(spacing: 0) {
                    if let currentTrack = playQueue.currentTrack {
                        MarqueeText(text: playQueue.name,
                                    font: UIFont.preferredFont(forTextStyle: .headline),
                                    leftFade: 16,
                                    rightFade: 16,
                                    startDelay: 3,
                                    alignment: .center)
                                    .padding()
                        
                        if let artwork = Utils.shared.loadImageFromDocuments(filePath: currentTrack.artwork) {
                            Image(uiImage: artwork)
                                .resizable()
                                .scaledToFit()
                                .frame(width: imageSize, height: imageSize)
                                .shadow(color: .black, radius: 5)
                        }
                        else {
                            Image(systemName: "music.note.list")
                                .font(.title)
                                .frame(width: imageSize, height: imageSize)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack {
                            MarqueeText(text: currentTrack.title,
                                        font: boldFont,
                                        leftFade: 16,
                                        rightFade: 16,
                                        startDelay: 3,
                                        alignment: .center)
                            
                            MarqueeText(text: currentTrack.artist,
                                        font: UIFont.preferredFont(forTextStyle: .headline),
                                        leftFade: 16,
                                        rightFade: 16,
                                        startDelay: 3,
                                        alignment: .center)
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
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Slider(value: $sliderValue, in: 0...1, step: 0.001, onEditingChanged: { editing in
                            isEditing = editing
                            if !editing {
                                isSeeking = true
                                if let player = playQueue.audioPlayer {
                                    let duration = player.currentItem?.duration.seconds ?? 1
                                    player.seek(to: CMTime(seconds: sliderValue * duration, preferredTimescale: 600), completionHandler: { finished in
                                        if finished {
                                            isSeeking = false
                                            playQueue.updateElapsedTime()
                                        }
                                    })
                                }
                            }
                        })
                        .padding()
                        .frame(height: 30)
                        .accentColor(.white)
                        
                        HStack {
                            if let player = playQueue.audioPlayer {
                                let duration = player.currentItem?.duration.seconds ?? 1
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
                                    .padding()
                            }
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
                                    .padding()
                            }
                            .disabled(playQueue.currentIndex == nil)
                        }
                        Button(action: {
                            impactHaptics.impactOccurred()
                            playQueue.prevTrack()
                        }) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding()
                        }
                        if playQueue.isPlaying {
                            Button(action: {
                                impactHaptics.impactOccurred()
                                playQueue.pausePlayback()
                            }) {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        else {
                            Button(action: {
                                impactHaptics.impactOccurred()
                                playQueue.resumePlayback()
                            }) {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Button(action: {
                            impactHaptics.impactOccurred()
                            playQueue.skipTrack()
                        }) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Button(action: {
                            impactHaptics.impactOccurred()
                            isQueuePresented = true
                        }) {
                            Image(systemName: "list.triangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                                .padding()
                        }
                        .disabled(playQueue.currentTrack == nil)
                    }
                    .padding(.top, 30)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "speaker.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .padding(.top, 5)
                        VolumeSlider()
                            .accentColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.top, 4)
                        Image(systemName: "speaker.wave.3.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.top, 20)
                }
                .onAppear {
                    UISlider.appearance().setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
                    if playQueue.currentTrack != nil {
                        guard let player = playQueue.audioPlayer else { return }
                        sliderValue = CMTimeGetSeconds(player.currentTime()) / player.currentItem!.duration.seconds
                        startTimer()
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                }
                .padding(.horizontal, 15)
            }
            .fullScreenCover(isPresented: $isQueuePresented) {
                QueueView(isPresented: $isQueuePresented)
            }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let player = playQueue.audioPlayer, !isEditing, !isSeeking else { return }
            sliderValue = CMTimeGetSeconds(player.currentTime()) / player.currentItem!.duration.seconds
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        guard timeInterval.isFinite else { return " 0:00" }
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
