//
//  Track.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/1/25.
//

import Foundation
import SwiftUI

struct Track: Codable, Identifiable {
    let id: UUID
    var artist: String
    var title: String
    var artwork: String?
    var path: String
    
    init(artist: String, artwork: String?, path: String) {
        self.id = UUID()
        self.artist = artist
        self.title = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        self.artwork = artwork
        self.path = path
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
        let trackIndex = tracks.firstIndex { $0.id == track.id }
        tracks[trackIndex!] = track
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func deleteTrack(_ track: Track) {
        var tracks = fetchTracks()
        self.deleteTrackFromDirectory(path: track.path)
        tracks.removeAll { $0.id == track.id }
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func deleteTrackFromDirectory(path: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let trackPath = documentsDirectory.appendingPathComponent(path)
            if fileManager.fileExists(atPath: trackPath.path) {
                try fileManager.removeItem(at: trackPath)
            }
        } catch {
            print("Failed to delete file at path: \(path)")
        }
    }
}
