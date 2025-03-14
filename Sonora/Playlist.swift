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
    var tracklist: [UUID]
    var lastPlayed: Date?
    var dateAdded: Date
    var duration: String
    
    init(name: String, artwork: UIImage?, tracklist: [UUID], duration: String) {
        self.id = UUID()
        self.name = name
        self.artwork = artwork?.jpegData(compressionQuality: 0.8)
        self.tracklist = tracklist
        self.lastPlayed = nil
        self.dateAdded = Date.now
        self.duration = duration
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
        let playlists = (try? JSONDecoder().decode([Playlist].self, from: data)) ?? []
        return playlists
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
        guard let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[playlistIndex] = playlist
        
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func removeFromAllPlaylists(for ids: [UUID]) {
        let playlists = fetchPlaylists()
        for var playlist in playlists {
            playlist.tracklist = playlist.tracklist.filter { !ids.contains($0) }
            replacePlaylist(playlist)
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
