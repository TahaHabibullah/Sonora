//
//  Album.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/17/25.
//

import Foundation
import SwiftUI

struct Album: Codable, Identifiable {
    let id: UUID
    var name: String
    var artist: String
    var artwork: String
    var smallArtwork: String
    var tracklist: [Track]
    var directory: String
    var lastPlayed: Date?
    var dateAdded: Date
    var duration: String
    
    init(name: String, artist: String, artwork: String, smallArtwork: String, tracklist: [Track], directory: String) {
        self.id = UUID()
        self.name = name
        self.artist = artist
        self.artwork = artwork
        self.smallArtwork = smallArtwork
        self.tracklist = tracklist
        self.directory = directory
        self.lastPlayed = nil
        self.dateAdded = Date.now
        self.duration = Utils.shared.getPlaylistDuration(from: tracklist.map { $0.path })
    }
}

class AlbumManager {
    static let shared = AlbumManager()
    private let storageKey = "sonoraAlbums"
    
    func fetchAlbums() -> [Album] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        let albums = (try? JSONDecoder().decode([Album].self, from: data)) ?? []
        return (try? JSONDecoder().decode([Album].self, from: data)) ?? []
    }
    
    func saveAlbum(_ album: Album) {
        var albums = fetchAlbums()
        albums.append(album)
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func replaceAlbum(_ album: Album) {
        var albums = fetchAlbums()
        guard let albumIndex = albums.firstIndex(where: { $0.id == album.id }) else { return }
        albums[albumIndex] = album
        
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func deleteAlbum(_ album: Album) {
        var albums = fetchAlbums()
        self.deleteAlbumDirectory(path: album.directory)
        albums.removeAll { $0.id == album.id }
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func deleteAlbumDirectory(path: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let trackPath = documentsDirectory.appendingPathComponent(path)
            if fileManager.fileExists(atPath: trackPath.path) {
                try fileManager.removeItem(at: trackPath)
            }
        } catch {
            print("Failed to delete directory: \(path)")
        }
    }
}
