//
//  PlayQueue.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI
import UIKit
import Foundation
import AVFoundation
import MediaPlayer

class PlayQueue: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var currentIndex: Int? = nil
    @Published var name: String = ""
    @Published var tracks: [String] = []
    @Published var titles: [String] = []
    @Published var artists: [String] = []
    @Published var artworks: [Data?] = []
    @Published var isPlaying: Bool = false
    @Published var audioPlayer: AVAudioPlayer?
    var playbackTimer: Timer?

    func startQueue(from track: String, in list: [String]) {
        currentIndex = list.firstIndex(of: track)
        if currentIndex != nil {
            tracks = list
            playCurrentTrack()
        }
    }
    
    func startQueue(from track: String, in album: Album) {
        currentIndex = album.tracks.firstIndex(of: track)
        if currentIndex != nil {
            do {
                setupRemoteTransportControls()
                observeAudioInterruptions()
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error configuring audio session: \(error.localizedDescription)")
            }
            name = album.name
            tracks = album.tracks
            titles = album.titles
            artworks = Array(repeating: album.artwork, count: album.titles.count)
            artists = Array(repeating: album.artists, count: album.titles.count)
            playCurrentTrack()
            startPlaybackUpdates()
        }
    }

    func playNextTrack() {
        if currentIndex == nil || currentIndex! >= tracks.count-1 {
            stopPlayback()
            return
        }
        currentIndex!+=1
        playCurrentTrack()
    }
    
    func playPreviousTrack() {
        guard currentIndex != nil else {
            stopPlayback()
            return
        }
        guard currentIndex! > 0 else {
            playCurrentTrack()
            return
        }
        currentIndex!-=1
        playCurrentTrack()
    }

    private func playCurrentTrack() {
        let fileManager = FileManager.default
        
        do {
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let trackPath = tracks[currentIndex!]
            let trackURL = documentsDirectory.appendingPathComponent(trackPath)
            
            audioPlayer = try AVAudioPlayer(contentsOf: trackURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            
            guard let player = audioPlayer else { return }
            var nowPlayingInfo: [String: Any] = [
                MPMediaItemPropertyTitle: titles[currentIndex!],
                MPMediaItemPropertyArtist: artists[currentIndex!],
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime
            ]
            
            if let artwork = artworks[currentIndex!] {
                if let image = UIImage(data: artwork) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
        } catch {
            print("Error playing track: \(error.localizedDescription)")
            stopPlayback()
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
    }

    func stopPlayback() {
        audioPlayer?.stop()
        stopPlaybackUpdates()
        isPlaying = false
        audioPlayer = nil
        currentIndex = nil
    }

    func skipTrack() {
        playNextTrack()
    }
    
    func prevTrack() {
        guard audioPlayer != nil else { return }
        if audioPlayer!.currentTime > 5 {
            playCurrentTrack()
        }
        else {
            playPreviousTrack()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextTrack()
    }
    
    func updateNowPlayingInfo() {
        guard let player = audioPlayer else { return }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: titles[currentIndex!],
            MPMediaItemPropertyArtist: artists[currentIndex!],
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime
        ]
        
        if let artwork = artworks[currentIndex!] {
            if let image = UIImage(data: artwork) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func startPlaybackUpdates() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateNowPlayingInfo()
        }
    }

    func stopPlaybackUpdates() {
        playbackTimer?.invalidate()
    }
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { _ in
            self.resumePlayback()
            return .success
        }

        commandCenter.pauseCommand.addTarget { _ in
            self.pausePlayback()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { _ in
            self.skipTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { _ in
            self.prevTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self.audioPlayer?.currentTime = event.positionTime
                self.updateNowPlayingInfo()
            }
            return .success
        }
    }
    
    private func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            isPlaying = false
            audioPlayer?.pause()

        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumePlayback()
                }
            }

        @unknown default:
            break
        }
    }
}
