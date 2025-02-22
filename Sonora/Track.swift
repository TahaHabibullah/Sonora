//
//  Track.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/1/25.
//

import Foundation
import SwiftUI

struct Track: Codable, Identifiable, Hashable {
    let id: UUID
    var artist: String
    var title: String
    var artwork: String?
    var smallArtwork: String?
    var path: String
    var duration: String
    
    init(artist: String, artwork: String?, smallArtwork: String?, path: String) {
        self.id = UUID()
        self.artist = artist
        self.title = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        self.artwork = artwork
        self.smallArtwork = smallArtwork
        self.path = path
        self.duration = Utils.shared.getTrackDuration(from: path)
    }
    
    init(artist: String, title: String, artwork: String?, smallArtwork: String?, path: String) {
        self.id = UUID()
        self.artist = artist
        self.title = title
        self.artwork = artwork
        self.smallArtwork = smallArtwork
        self.path = path
        self.duration = Utils.shared.getTrackDuration(from: path)
    }
}

class TrackManager {
    static let shared = TrackManager()
    private let storageKey = "sonoraTracks"
    
    func fetchTracks() -> [Track] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        let tracks = (try? JSONDecoder().decode([Track].self, from: data)) ?? []
        return (try? JSONDecoder().decode([Track].self, from: data)) ?? []
    }
    
    func saveTrack(_ track: Track) {
        var tracks = fetchTracks()
        tracks.append(track)
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func replaceTrack(_ track: Track) {
        var tracks = fetchTracks()
        guard let trackIndex = tracks.firstIndex (where: { $0.id == track.id }) else { return }
        tracks[trackIndex] = track
        
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func deleteTrack(_ track: Track) {
        var tracks = fetchTracks()
        self.deleteTrackFromDirectory(trackPath: track.path, artworkPath: track.artwork)
        tracks.removeAll { $0.id == track.id }
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func deleteTrackFromDirectory(trackPath: String, artworkPath: String?) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let trackURL = documentsDirectory.appendingPathComponent(trackPath)
            if fileManager.fileExists(atPath: trackURL.path) {
                try fileManager.removeItem(at: trackURL)
            }
        } catch {
            print("Failed to delete file at path: \(trackPath)")
        }
        
        do {
            if let path = artworkPath {
                let smallPath = Utils.shared.getSmallArtworkPath(from: path)
                let artworkURL = documentsDirectory.appendingPathComponent(path)
                let smallArtworkURL = documentsDirectory.appendingPathComponent(smallPath!)
                if fileManager.fileExists(atPath: artworkURL.path) {
                    try fileManager.removeItem(at: artworkURL)
                    try fileManager.removeItem(at: smallArtworkURL)
                }
            }
        } catch {
            print("Failed to delete file at path: \(artworkPath != nil ? artworkPath! : "No artwork path")")
        }
    }
}
