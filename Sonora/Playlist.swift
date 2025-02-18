//
//  Playlist.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/5/25.
//

import Foundation
import SwiftUI

struct Playlist: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var artwork: Data?
    var tracklist: [Track]
    var lastPlayed: Date?
    var dateAdded: Date
    var duration: String
    
    init(name: String, artwork: UIImage?, tracklist: [Track]) {
        self.id = UUID()
        self.name = name
        self.artwork = artwork?.jpegData(compressionQuality: 0.8)
        self.tracklist = tracklist
        self.lastPlayed = nil
        self.dateAdded = Date.now
        self.duration = Utils.shared.getPlaylistDuration(from: tracklist.map { $0.path })
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.artwork = nil
        self.tracklist = []
        self.lastPlayed = nil
        self.dateAdded = Date.now
        self.duration = "0h 0m"
    }
    
    mutating func replaceArtwork(_ artwork: UIImage) {
        self.artwork = artwork.jpegData(compressionQuality: 0.8)
    }
}

class PlaylistManager {
    static let shared = PlaylistManager()
    private let storageKey = "sonoraPlaylists"
    
    func fetchPlaylists() -> [Playlist] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        let tracks = (try? JSONDecoder().decode([Playlist].self, from: data)) ?? []
        return (try? JSONDecoder().decode([Playlist].self, from: data)) ?? []
    }
    
    func fetchPlaylist(_ id: UUID) -> Playlist {
        let playlists = fetchPlaylists()
        return playlists[playlists.firstIndex(where: { $0.id == id})!]
    }
    
    func savePlaylist(_ playlist: Playlist) {
        var playlists = fetchPlaylists()
        playlists.append(playlist)
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func replacePlaylist(_ playlist: Playlist) {
        var playlists = fetchPlaylists()
        let playlistIndex = playlists.firstIndex { $0.id == playlist.id }
        playlists[playlistIndex!] = playlist
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        var playlists = fetchPlaylists()
        playlists.removeAll { $0.id == playlist.id }
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
