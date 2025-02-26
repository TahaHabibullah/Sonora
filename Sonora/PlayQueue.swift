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
    @Published var currentTrack: Track? = nil
    @Published var currentIndex: Int? = nil
    @Published var name: String = ""
    @Published var tracklist: [Track] = []
    @Published var originalTracklist: [Track] = []
    @Published var trackQueue: [Track] = []
    @Published var isPlaying: Bool = false
    @Published var isShuffled: Bool = false
    @Published var audioPlayer: AVAudioPlayer?
    @Published var originalName: String = ""
    private let saveStateKey = "savedPlayQueueState"
    var playbackTimer: Timer?
    
    override init() {
        super.init()
        setupRemoteTransportControls()
        observeAudioInterruptions()
        loadPlaybackState()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
    }
    
    func startQueue(from track: Int, in album: Album, tracks: [Track]) {
        currentIndex = track
        if currentIndex != nil {
            originalTracklist = tracks
            tracklist = tracks
            
            originalName = album.name
            name = album.name
            isShuffled = false
            playCurrentTrack()
            startPlaybackUpdates()
        }
    }
    
    func startShuffledQueue(from album: Album, tracks: [Track]) {
        currentIndex = 0
        originalTracklist = tracks
        originalName = album.name
        name = album.name
        
        let shuffledIndices = tracks.indices.shuffled()
        tracklist = shuffledIndices.map { tracks[$0] }
        
        isShuffled = true
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func startPlaylistQueue(from track: Track, in tracks: [Track], playlistName: String = "Loose Tracks") {
        originalTracklist = tracks
        originalName = playlistName
        currentIndex = 0
        
        let tracklistIds = tracks.map { $0.id }
        let trackIndex = tracklistIds.firstIndex(of: track.id)
        var trackListCopy = tracks
        trackListCopy.remove(at: trackIndex!)
        
        let shuffledIndices = trackListCopy.indices.shuffled()
        var shuffledTracklist = shuffledIndices.map { trackListCopy[$0] }
        shuffledTracklist.insert(track, at: 0)
        
        name = playlistName
        tracklist = shuffledTracklist
        isShuffled = true
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func startPlaylistQueueUnshuffled(from tracks: [Track], playlistName: String) {
        originalTracklist = tracks
        tracklist = tracks
        currentIndex = 0
        
        if playlistName.isEmpty {
            originalName = "Untitled Playlist"
            name = "Untitled Playlist"
        }
        else {
            originalName = playlistName
            name = playlistName
        }
        isShuffled = false
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func startPlaylistQueueShuffled(from tracks: [Track], playlistName: String) {
        originalTracklist = tracks
        currentIndex = 0
        
        let shuffledIndices = tracks.indices.shuffled()
        if playlistName.isEmpty {
            originalName = "Untitled Playlist"
            name = "Untitled Playlist"
        }
        else {
            originalName = playlistName
            name = playlistName
        }
        tracklist = shuffledIndices.map { tracks[$0] }
        isShuffled = true
        playCurrentTrack()
        startPlaybackUpdates()
    }
    
    func shuffleTracks() {
        guard currentIndex != nil else { return }
        
        var trackQueue = tracklist
        trackQueue.remove(at: currentIndex!)
        
        let shuffledIndices = trackQueue.indices.shuffled()
        var shuffledTrackQueue = shuffledIndices.map { trackQueue[$0] }
        
        let currentTrack = tracklist[currentIndex!]
        shuffledTrackQueue.insert(currentTrack, at: 0)
        
        tracklist = shuffledTrackQueue
        currentIndex = 0
        isShuffled = true
    }
    
    func unshuffleTracks() {
        guard currentIndex != nil else { return }
        
        let currentId = tracklist[currentIndex!].id
        currentIndex = originalTracklist.firstIndex(where: { $0.id == currentId })!
        tracklist = originalTracklist
        isShuffled = false
    }
    
    func addToQueue(_ track: Track) {
        trackQueue.append(track)
        guard currentIndex != nil else {
            isShuffled = false
            currentIndex = 0
            name = "Queue"
            playNextQueueTrack()
            startPlaybackUpdates()
            return
        }
    }

    func playNextTrack() {
        guard currentIndex != nil else {
            stopPlayback()
            return
        }
        guard currentIndex! < tracklist.count-1 else {
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
            let trackPath = tracklist[currentIndex!].path
            let trackURL = documentsDirectory.appendingPathComponent(trackPath)
            
            audioPlayer = try AVAudioPlayer(contentsOf: trackURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            name = originalName
            
            currentTrack = tracklist[currentIndex!]
            
            guard let player = audioPlayer else { return }
            
            var nowPlayingInfo: [String: Any] = [
                MPMediaItemPropertyTitle: tracklist[currentIndex!].title,
                MPMediaItemPropertyArtist: tracklist[currentIndex!].artist,
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime
            ]
            
            let artworkPath = tracklist[currentIndex!].artwork
            if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            savePlaybackState()
            
        } catch {
            print("Error playing track: \(error.localizedDescription)")
            stopPlayback()
        }
    }
    
    func playNextQueueTrack() {
        let fileManager = FileManager.default
        
        do {
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let track = trackQueue.removeFirst()
            let trackPath = track.path
            let trackURL = documentsDirectory.appendingPathComponent(trackPath)
            
            audioPlayer = try AVAudioPlayer(contentsOf: trackURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            name = "Queue"
            currentTrack = track
            
            guard let player = audioPlayer else { return }
            
            var nowPlayingInfo: [String: Any] = [
                MPMediaItemPropertyTitle: track.title,
                MPMediaItemPropertyArtist: track.artist,
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime
            ]
            
            let artworkPath = track.artwork
            if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
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
        savePlaybackState()
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
        currentTrack = nil
        isShuffled = false
        name = ""
        savePlaybackState(reset: true)
    }
    
    func skipToTrack(_ index: Int) {
        currentIndex = index
        playCurrentTrack()
    }
    
    func skipQueueToTrack(_ index: Int) {
        trackQueue.removeFirst(index)
        playNextQueueTrack()
    }

    func skipTrack() {
        if trackQueue.isEmpty {
            playNextTrack()
        }
        else {
            playNextQueueTrack()
        }
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
        if trackQueue.isEmpty {
            playNextTrack()
        }
        else {
            playNextQueueTrack()
        }
    }
    
    func updateNowPlayingInfo() {
        guard let player = audioPlayer else { return }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: currentTrack!.title,
            MPMediaItemPropertyArtist: currentTrack!.artist,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime
        ]
        
        let artworkPath = currentTrack!.artwork
        if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlaybackStateOnExit),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlaybackStateOnExit),
            name: UIApplication.didEnterBackgroundNotification,
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
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        if reason == .oldDeviceUnavailable {
            isPlaying = false
            audioPlayer?.pause()
        }
    }
    
    private func savePlaybackState(reset: Bool = false) {
        let saveState = PlayQueueState(tracklist: tracklist,
                                   originalTracklist: originalTracklist,
                                   trackQueue: trackQueue,
                                   currentTrack: currentTrack,
                                   currentIndex: currentIndex,
                                   currentPlaybackTime: reset ? 0 : audioPlayer?.currentTime ?? 0,
                                   name: name,
                                   originalName: originalName,
                                   isShuffled: isShuffled)

        if let data = try? JSONEncoder().encode(saveState) {
            UserDefaults.standard.set(data, forKey: "savedPlayQueueState")
        }
    }
    
    @objc private func savePlaybackStateOnExit() {
        savePlaybackState()
    }
    
    private func loadPlaybackState() {
        guard let data = UserDefaults.standard.data(forKey: saveStateKey) else { return }
        let saveState = (try? JSONDecoder().decode(PlayQueueState.self, from: data)) ?? nil
        if let state = saveState {
            self.originalTracklist = state.originalTracklist
            self.tracklist = state.tracklist
            self.trackQueue = state.trackQueue
            self.name = state.name
            self.originalName = state.originalName
            self.currentTrack = state.currentTrack
            self.currentIndex = state.currentIndex
            self.isShuffled = state.isShuffled
        
            if let track = currentTrack {
                let fileManager = FileManager.default
                do {
                    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let trackPath = track.path
                    let trackURL = documentsDirectory.appendingPathComponent(trackPath)
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: trackURL)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.delegate = self
                    audioPlayer?.currentTime = state.currentPlaybackTime
                } catch {
                    print("Error setting up save state track: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct PlayQueueState: Codable {
    var tracklist: [Track]
    var originalTracklist: [Track]
    var trackQueue: [Track]
    var currentTrack: Track?
    var currentIndex: Int?
    var currentPlaybackTime: TimeInterval
    var name: String
    var originalName: String
    var isShuffled: Bool
}
