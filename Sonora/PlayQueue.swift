//
//  PlayQueue.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/21/25.
//

import SwiftUI
import Foundation
import AVFoundation
import MediaPlayer

class PlayQueue: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var currentIndex: Int? = nil
    @Published var name: String = ""
    @Published var tracks: [String] = []
    @Published var titles: [String] = []
    @Published var artists: [String] = []
    @Published var artworks: [String?] = []
    @Published var isPlaying: Bool = false
    @Published var isShuffled: Bool = false
    @Published var audioPlayer: AVAudioPlayer?
    var playbackTimer: Timer?
    private var originalTracks: [String] = []
    private var originalTitles: [String] = []
    private var originalArtists: [String] = []
    private var originalArtworks: [String?] = []
    
    override init() {
        super.init()
        setupRemoteTransportControls()
        observeAudioInterruptions()
    }

    func startQueue(from track: Track, in trackList: [Track], playListName: String = "") {
        let trackPath = track.path
        let trackPaths = trackList.map { $0.path }
        let trackIndex = trackPaths.firstIndex(of: trackPath)
        var trackListCopy = trackList
        trackListCopy.remove(at: trackIndex!)
        
        originalTracks = trackList.map { $0.path }
        originalTitles = trackList.map { $0.title }
        originalArtists = trackList.map { $0.artist }
        originalArtworks = trackList.map { $0.artwork }
        currentIndex = 0
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
        
        let tracksQueue = trackListCopy.map { $0.path }
        let artistsQueue = trackListCopy.map { $0.artist }
        let titlesQueue = trackListCopy.map { $0.title }
        let artworksQueue = trackListCopy.map { $0.artwork }
        
        let shuffledIndices = tracksQueue.indices.shuffled()
        var shuffledTracksQueue = shuffledIndices.map { tracksQueue[$0] }
        var shuffledTitlesQueue = shuffledIndices.map { titlesQueue[$0] }
        var shuffledArtistsQueue = shuffledIndices.map { artistsQueue[$0] }
        var shuffledArtworksQueue = shuffledIndices.map { artworksQueue[$0] }
        
        shuffledTracksQueue.insert(trackPath, at: 0)
        shuffledTitlesQueue.insert(track.title, at: 0)
        shuffledArtistsQueue.insert(track.artist, at: 0)
        shuffledArtworksQueue.insert(track.artwork, at: 0)
        
        if playListName.isEmpty {
            name = "Loose Tracks"
        }
        else {
            name = playListName
        }
        tracks = shuffledTracksQueue
        titles = shuffledTitlesQueue
        artists = shuffledArtistsQueue
        artworks = shuffledArtworksQueue
        isShuffled = true
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func startQueue(from track: Int, in album: Album) {
        currentIndex = track
        if currentIndex != nil {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error configuring audio session: \(error.localizedDescription)")
            }
            name = album.name
            tracks = album.tracks
            titles = album.titles
            artworks = Array(repeating: album.artwork, count: album.titles.count)
            artists = Array(repeating: album.artist, count: album.titles.count)
            
            originalTracks = album.tracks
            originalTitles = album.titles
            originalArtworks = Array(repeating: album.artwork, count: album.titles.count)
            originalArtists = Array(repeating: album.artist, count: album.titles.count)
            isShuffled = false
            playCurrentTrack()
            startPlaybackUpdates()
        }
    }
    
    func startShuffledQueue(from album: Album) {
        currentIndex = 0
        if currentIndex != nil {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error configuring audio session: \(error.localizedDescription)")
            }
        }
        name = album.name
        let shuffledIndices = album.tracks.indices.shuffled()
        originalTracks = album.tracks
        originalTitles = album.titles
        originalArtworks = Array(repeating: album.artwork, count: album.titles.count)
        originalArtists = Array(repeating: album.artist, count: album.titles.count)
        
        tracks = shuffledIndices.map { album.tracks[$0] }
        titles = shuffledIndices.map { album.titles[$0] }
        artworks = Array(repeating: album.artwork, count: album.titles.count)
        artists = Array(repeating: album.artist, count: album.titles.count)
        isShuffled = true
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func shuffleTracks() {
        if currentIndex == nil {
            return
        }
        
        var trackQueue = tracks
        var titlesQueue = titles
        var artistsQueue = artists
        var artworksQueue = artworks
        trackQueue.remove(at: currentIndex!)
        titlesQueue.remove(at: currentIndex!)
        artistsQueue.remove(at: currentIndex!)
        artworksQueue.remove(at: currentIndex!)
        
        let shuffledIndices = trackQueue.indices.shuffled()
        var shuffledQueueTracks = shuffledIndices.map { trackQueue[$0] }
        var shuffledQueueTitles = shuffledIndices.map { titlesQueue[$0] }
        var shuffledQueueArtists = shuffledIndices.map { artistsQueue[$0] }
        var shuffledQueueArtworks = shuffledIndices.map { artworksQueue[$0] }
        
        let currentTrack = tracks[currentIndex!]
        let currentTitle = titles[currentIndex!]
        let currentArtist = artists[currentIndex!]
        let currentArtwork = artworks[currentIndex!]
        
        shuffledQueueTitles.insert(currentTitle, at: 0)
        shuffledQueueTracks.insert(currentTrack, at: 0)
        shuffledQueueArtists.insert(currentArtist, at: 0)
        shuffledQueueArtworks.insert(currentArtwork, at: 0)
        
        tracks = shuffledQueueTracks
        titles = shuffledQueueTitles
        artists = shuffledQueueArtists
        artworks = shuffledQueueArtworks
        currentIndex = 0
        isShuffled = true
    }
    
    func unshuffleTracks() {
        if currentIndex == nil {
            return
        }
        
        let currentTrack = tracks[currentIndex!]
        currentIndex = originalTracks.firstIndex(where: { $0 == currentTrack })!
        tracks = originalTracks
        titles = originalTitles
        artists = originalArtists
        artworks = originalArtworks
        isShuffled = false
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
            
            if let artworkPath = artworks[currentIndex!] {
                if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        isPlaying = false
        audioPlayer = nil
        currentIndex = nil
        name = ""
        tracks = []
        artists = []
        titles = []
        artworks = []
    }
    
    func skipToTrack(_ index: Int) {
        currentIndex = index
        playCurrentTrack()
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
        
        if let artworkPath = artworks[currentIndex!] {
            if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func startPlaybackUpdates() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
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
