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
    var artwork: Data?
    var tracks: [URL]
    
    init(name: String, artwork: UIImage?, tracks: [URL]) {
        self.id = UUID()
        self.name = name
        self.artwork = artwork?.jpegData(compressionQuality: 0.8)
        self.tracks = tracks
    }
}

class AlbumManager {
    static let shared = AlbumManager()
    private let storageKey = "savedAlbums"
    
    func fetchAlbums() -> [Album] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
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
        albums[albums.firstIndex(where: { $0.id == album.id })!] = album
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func deleteAlbum(_ album: Album) {
        var albums = fetchAlbums()
        albums.removeAll { $0.id == album.id }
        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
