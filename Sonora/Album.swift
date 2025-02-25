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
    var directory: String
    var lastPlayed: Date?
    var dateAdded: Date
    
    init(name: String, artist: String, artwork: String, smallArtwork: String, directory: String) {
        self.id = UUID()
        self.name = name
        self.artist = artist
        self.artwork = artwork
        self.smallArtwork = smallArtwork
        self.directory = directory
        self.lastPlayed = nil
        self.dateAdded = Date.now
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
        deleteAlbumFromDocuments(album: album)
        albums.removeAll { $0.id == album.id }
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func deleteAlbumFromDocuments(album: Album) {
        let path = album.directory
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tracklist = TrackManager.shared.fetchTracks(key: path)
        
        do {
            for track in tracklist {
                if track.artwork != album.artwork {
                    let artworkPath = documentsDirectory.appendingPathComponent(track.artwork)
                    let smallArtworkPath = documentsDirectory.appendingPathComponent(track.smallArtwork)
                    if fileManager.fileExists(atPath: artworkPath.path) {
                        try fileManager.removeItem(at: artworkPath)
                        try fileManager.removeItem(at: smallArtworkPath)
                    }
                }
            }
            
            let directory = documentsDirectory.appendingPathComponent(path)
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        } catch {
            print("Failed to delete directory: \(path)")
        }
    }
}
