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
    @Published var originalName: String = ""
    @Published var tracklist: [Track] = []
    @Published var originalTracklist: [Track] = []
    @Published var trackQueue: [Track] = []
    @Published var isPlaying: Bool = false
    @Published var isShuffled: Bool = false
    @Published var isRepeatingTrack: Bool = false
    @Published var isRepeatingQueue: Bool = false
    @Published var audioPlayer: AVQueuePlayer?
    @State private var isSeeking: Bool = false
    private var info: [String : Any] = [:]
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
    
    func startUnshuffledQueue(from track: Track? = nil, tracks: [Track], playlistName: String) {
        originalTracklist = tracks
        tracklist = tracks
        originalName = playlistName
        name = playlistName
        
        if let track = track {
            let tracklistIds = tracks.map { $0.id }
            currentIndex = tracklistIds.firstIndex(of: track.id)
        }
        else {
            currentIndex = 0
        }
        
        isShuffled = false
        isRepeatingTrack = false
        currentTrack = tracklist[currentIndex!]
        let currentItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[currentIndex!])
        audioPlayer = AVQueuePlayer(items: [currentItem])
        audioPlayer?.play()
        playCurrentTrack()
    }
    
    func startShuffledQueue(from track: Track? = nil, tracks: [Track], playlistName: String) {
        originalTracklist = tracks
        originalName = playlistName
        name = playlistName
        
        if let track = track {
            let tracklistIds = tracks.map { $0.id }
            let trackIndex = tracklistIds.firstIndex(of: track.id)
            var trackListCopy = tracks
            trackListCopy.remove(at: trackIndex!)
            
            var shuffledTracklist = trackListCopy.shuffled()
            shuffledTracklist.insert(track, at: 0)
            tracklist = shuffledTracklist
        }
        else {
            tracklist = tracks.shuffled()
        }
        
        currentIndex = 0
        isShuffled = true
        isRepeatingTrack = false
        currentTrack = tracklist[0]
        let currentItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[0])
        audioPlayer = AVQueuePlayer(items: [currentItem])
        audioPlayer?.play()
        playCurrentTrack()
    }
    
    func shuffleTracks() {
        guard currentIndex != nil else { return }
        guard !tracklist.isEmpty else { return }
        
        var tracks = tracklist
        tracks.remove(at: currentIndex!)
        
        let shuffledIndices = tracks.indices.shuffled()
        var shuffledTrackQueue = shuffledIndices.map { tracks[$0] }
        
        let currentTrack = tracklist[currentIndex!]
        shuffledTrackQueue.insert(currentTrack, at: 0)
        
        tracklist = shuffledTrackQueue
        currentIndex = 0
        isShuffled = true
        replaceNextItem()
    }
    
    func unshuffleTracks() {
        guard currentIndex != nil else { return }
        guard !tracklist.isEmpty else { return }
        
        let currentId = tracklist[currentIndex!].id
        currentIndex = originalTracklist.firstIndex(where: { $0.id == currentId })!
        tracklist = originalTracklist
        isShuffled = false
        replaceNextItem()
    }
    
    func addToQueue(_ track: Track) {
        if currentIndex == nil {
            isShuffled = false
            isRepeatingTrack = false
            isRepeatingQueue = false
            currentIndex = 0
            originalName = "Queue"
            currentTrack = track
            let currentItem = Utils.shared.convertTrackToAVPlayerItem(from: track)
            audioPlayer = AVQueuePlayer(items: [currentItem])
            audioPlayer?.play()
            playCurrentTrack()
        }
        else {
            if trackQueue.isEmpty {
                trackQueue.append(track)
                replaceNextItem()
            }
            else {
                trackQueue.append(track)
            }
        }
    }

    func playNextTrack() {
        if isRepeatingTrack {
            audioPlayer?.advanceToNextItem()
            audioPlayer?.play()
            isPlaying = true
            playCurrentTrack()
            return
        }
        if trackQueue.isEmpty {
            guard currentIndex != nil else {
                stopPlayback()
                return
            }
            guard currentIndex! < tracklist.count-1 else {
                if isRepeatingQueue {
                    if originalTracklist.isEmpty {
                        stopPlayback()
                        return
                    }
                    if isShuffled {
                        startShuffledQueue(tracks: originalTracklist, playlistName: originalName)
                        return
                    }
                    else {
                        startUnshuffledQueue(tracks: originalTracklist, playlistName: originalName)
                        return
                    }
                }
                stopPlayback()
                return
            }
            name = originalName
            currentIndex!+=1
            currentTrack = tracklist[currentIndex!]
        }
        else {
            name = "Queue"
            currentTrack = trackQueue.removeFirst()
        }
        audioPlayer?.advanceToNextItem()
        audioPlayer?.play()
        isPlaying = true
        playCurrentTrack()
    }
    
    func playPreviousTrack() {
        guard currentIndex != nil else {
            stopPlayback()
            return
        }
        guard currentIndex! > 0 else {
            audioPlayer?.seek(to: .zero, completionHandler: { finished in
                if finished {
                    DispatchQueue.main.async {
                        self.info[MPNowPlayingInfoPropertyPlaybackRate] = 0
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
                        self.info[MPNowPlayingInfoPropertyPlaybackRate] = 1
                        self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
                    }
                }
            })
            return
        }
        let lastItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[currentIndex!-1])
        currentIndex!-=1
        audioPlayer = AVQueuePlayer(items: [lastItem])
        audioPlayer?.play()
        currentTrack = tracklist[currentIndex!]
        playCurrentTrack()
    }

    func playCurrentTrack() {
        isPlaying = true
        
        guard let player = audioPlayer else { return }
        info[MPMediaItemPropertyTitle] = self.currentTrack!.title
        info[MPMediaItemPropertyArtist] = self.currentTrack!.artist
        info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(player.currentItem!.asset.duration)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        info[MPNowPlayingInfoPropertyPlaybackProgress] = 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        let artworkPath = currentTrack!.artwork
        if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
        if isRepeatingTrack {
            let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: currentTrack!)
            audioPlayer?.insert(nextItem, after: nil)
        }
        else if !trackQueue.isEmpty {
            let nextTrack = trackQueue.first!
            let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: nextTrack)
            audioPlayer?.insert(nextItem, after: nil)
        }
        else if currentIndex! < tracklist.count-1 {
            let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[currentIndex!+1])
            audioPlayer?.insert(nextItem, after: nil)
        }
        savePlaybackState()
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        DispatchQueue.main.async {
            if let player = self.audioPlayer {
                let elapsedTime = CMTimeGetSeconds(player.currentTime())
                self.info[MPNowPlayingInfoPropertyPlaybackRate] = 0
                self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
                MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
            }
        }
        savePlaybackState()
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        DispatchQueue.main.async {
            if let player = self.audioPlayer {
                let elapsedTime = CMTimeGetSeconds(player.currentTime())
                self.info[MPNowPlayingInfoPropertyPlaybackRate] = 1
                self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
                MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
            }
        }
        isPlaying = true
    }

    func stopPlayback() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        isPlaying = false
        audioPlayer = nil
        currentIndex = nil
        currentTrack = nil
        isShuffled = false
        isRepeatingTrack = false
        isRepeatingQueue = false
        tracklist = []
        originalTracklist = []
        name = ""
        originalName = ""
        savePlaybackState(reset: true)
    }
    
    func skipToTrack(_ index: Int) {
        currentIndex = index
        currentTrack = tracklist[index]
        let currentItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[index])
        audioPlayer = AVQueuePlayer(items: [currentItem])
        audioPlayer?.play()
        name = originalName
        isRepeatingTrack = false
        playCurrentTrack()
    }
    
    func skipQueueToTrack(_ index: Int) {
        trackQueue.removeFirst(index)
        let track = trackQueue.removeFirst()
        currentTrack = track
        let trackItem = Utils.shared.convertTrackToAVPlayerItem(from: track)
        audioPlayer = AVQueuePlayer(items: [trackItem])
        audioPlayer?.play()
        name = "Queue"
        isRepeatingTrack = false
        playCurrentTrack()
    }

    func skipTrack() {
        isRepeatingTrack = false
        playNextTrack()
    }
    
    func prevTrack() {
        guard audioPlayer != nil else { return }
        let currentTime = CMTimeGetSeconds(audioPlayer?.currentTime() ?? CMTime.zero)
        if currentTime > 5 {
            audioPlayer?.seek(to: .zero, completionHandler: { finished in
                if finished {
                    DispatchQueue.main.async {
                        self.info[MPNowPlayingInfoPropertyPlaybackRate] = 0
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
                        self.info[MPNowPlayingInfoPropertyPlaybackRate] = 1
                        self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
                    }
                }
            })
        }
        else {
            isRepeatingTrack = false
            playPreviousTrack()
        }
    }
    
    func updateNowPlayingInfo() {
        guard let player = audioPlayer else { return }
        let duration = player.currentItem?.duration.seconds ?? 1
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        info[MPNowPlayingInfoPropertyPlaybackProgress] = elapsedTime / duration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    func replaceNextItem() {
        if let items = audioPlayer?.items() {
            if items.count > 1 {
                audioPlayer?.remove(items[1])
            }
            if isRepeatingTrack {
                let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: currentTrack!)
                audioPlayer?.insert(nextItem, after: nil)
            }
            else if trackQueue.isEmpty {
                if currentIndex! < tracklist.count-1 {
                    let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[currentIndex!+1])
                    audioPlayer?.insert(nextItem, after: nil)
                }
            }
            else {
                let nextTrack = trackQueue.first!
                let nextItem = Utils.shared.convertTrackToAVPlayerItem(from: nextTrack)
                audioPlayer?.insert(nextItem, after: nil)
            }
        }
    }
    
    func updateElapsedTime() {
        guard let player = audioPlayer else { return }
        DispatchQueue.main.async {
            let elapsedTime = CMTimeGetSeconds(player.currentTime())
            self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
        }
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
                self.audioPlayer?.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 600))
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil)
    }
    
    @objc func trackDidFinish(notification: Notification) {
        playNextTrack()
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
                                   currentPlaybackTime: audioPlayer?.currentTime().seconds ?? 0.0,
                                   name: name,
                                   originalName: originalName,
                                   isShuffled: isShuffled,
                                   isRepeatingTrack: isRepeatingTrack,
                                   isRepeatingQueue: isRepeatingQueue)

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
            self.isRepeatingTrack = state.isRepeatingTrack
            self.isRepeatingQueue = state.isRepeatingQueue
        
            if let track = currentTrack {
                let currentItem = Utils.shared.convertTrackToAVPlayerItem(from: track)
                audioPlayer = AVQueuePlayer(items: [currentItem])
                audioPlayer?.seek(to: CMTime(seconds: state.currentPlaybackTime, preferredTimescale: 600))
                if !trackQueue.isEmpty {
                    let nextTrack = trackQueue.first!
                    let nextTrackItem = Utils.shared.convertTrackToAVPlayerItem(from: nextTrack)
                    audioPlayer?.insert(nextTrackItem, after: nil)
                }
                else if currentIndex! < tracklist.count-1 {
                    let nextTrackItem = Utils.shared.convertTrackToAVPlayerItem(from: tracklist[currentIndex!+1])
                    audioPlayer?.insert(nextTrackItem, after: nil)
                }
                
                guard let player = audioPlayer else { return }
                let duration = CMTimeGetSeconds(player.currentItem!.asset.duration)
                let elapsedTime = state.currentPlaybackTime
                info[MPMediaItemPropertyTitle] = self.currentTrack!.title
                info[MPMediaItemPropertyArtist] = self.currentTrack!.artist
                info[MPMediaItemPropertyPlaybackDuration] = duration
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
                info[MPNowPlayingInfoPropertyPlaybackProgress] = elapsedTime / duration
                
                let artworkPath = currentTrack!.artwork
                if let image = Utils.shared.loadImageFromDocuments(filePath: artworkPath) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    info[MPMediaItemPropertyArtwork] = artwork
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
    var isRepeatingTrack: Bool
    var isRepeatingQueue: Bool
}
