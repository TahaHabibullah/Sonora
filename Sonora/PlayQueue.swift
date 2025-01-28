//
//  PlayQueue.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI
import Foundation
import AVFoundation

class PlayQueue: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var currentIndex: Int? = nil
    @Published var name: String = ""
    @Published var tracks: [String] = []
    @Published var titles: [String] = []
    @Published var artists: [String] = []
    @Published var artworks: [Data?] = []
    @Published var isPlaying: Bool = false
    @Published var audioPlayer: AVAudioPlayer?

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
            name = album.name
            tracks = album.tracks
            titles = album.titles
            artworks = Array(repeating: album.artwork, count: album.titles.count)
            artists = Array(repeating: album.artists, count: album.titles.count)
            playCurrentTrack()
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
}
