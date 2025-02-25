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
    var artwork: String
    var smallArtwork: String
    var path: String
    var duration: String
    
    init(artist: String, artwork: String, smallArtwork: String, path: String) {
        self.id = UUID()
        self.artist = artist
        self.title = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        self.artwork = artwork
        self.smallArtwork = smallArtwork
        self.path = path
        self.duration = Utils.shared.getTrackDuration(from: path)
    }
    
    init(artist: String, title: String, artwork: String, smallArtwork: String, path: String) {
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
    private var tracks: [String: [Track]] = [:]
    private let storageKey = "sonoraTracks"
    
    private init() {
        loadTracks()
    }
    
    func fetchTracks(key: String) -> [Track] {
        return tracks[key] ?? []
    }
    
    func fetchAllTracks() -> [Track] {
        return tracks.values.flatMap { $0 }
    }
    
    func fetchPlaylist(from ids: [UUID]) -> [Track] {
        let idSet = Set(ids)
        let allTracks = tracks.values.flatMap { $0 }
        let tracklist = allTracks.filter { idSet.contains($0.id) }
        let orderedTracklist = ids.compactMap { id in
            tracklist.first { $0.id == id }
        }
        return orderedTracklist
    }

    func addTrack(_ track: Track, key: String) {
        if tracks[key] != nil {
            tracks[key]?.append(track)
        } else {
            tracks[key] = [track]
        }
        saveTracks()
    }
    
    func addTracklist(_ tracklist: [Track], key: String) {
        if tracks[key] != nil {
            tracks[key]?.append(contentsOf: tracklist)
        } else {
            tracks[key] = tracklist
        }
        saveTracks()
    }
    
    func deleteLooseTrack(_ track: Track) {
        let key = "Loose_Tracks"
        guard var tracklist = tracks[key] else { return }
        tracklist.removeAll { $0.id == track.id }
        if tracklist.isEmpty {
            tracks.removeValue(forKey: key)
        }
        else {
            tracks[key] = tracklist
        }
        deleteLooseTrackFromDocuments(track: track)
        PlaylistManager.shared.removeFromAllPlaylists(for: [track.id])
        saveTracks()
    }
    
    func deleteTracksFromAlbum(from key: String, with ids: [UUID]) {
        guard let tracklist = tracks[key] else { return }
        let idSet = Set(ids)
        tracks[key] = tracklist.filter { !idSet.contains($0.id) }
        PlaylistManager.shared.removeFromAllPlaylists(for: ids)
        saveTracks()
    }
    
    func deleteAlbumTracklist(from key: String) {
        guard let tracklist = tracks[key] else { return }
        tracks.removeValue(forKey: key)
        PlaylistManager.shared.removeFromAllPlaylists(for: tracklist.map { $0.id })
        saveTracks()
    }
    
    func replaceTrack(_ track: Track, from key: String) {
        guard var tracklist = tracks[key] else { return }
        guard let trackIndex = tracklist.firstIndex(where: { $0.id == track.id }) else { return }
        tracklist[trackIndex] = track
        tracks[key] = tracklist
        saveTracks()
    }
    
    func replaceTracklist(_ tracklist: [Track], for key: String) {
        tracks[key] = tracklist
        saveTracks()
    }
    
    private func saveTracks() {
        if let encodedData = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(encodedData, forKey: storageKey)
        }
    }
    
    private func loadTracks() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let decodedTracks = try? JSONDecoder().decode([String: [Track]].self, from: savedData) {
            tracks = decodedTracks
        }
    }
    
    private func deleteLooseTrackFromDocuments(track: Track) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let trackURL = documentsDirectory.appendingPathComponent(track.path)
            if fileManager.fileExists(atPath: trackURL.path) {
                try fileManager.removeItem(at: trackURL)
            }
        } catch {
            print("Failed to delete file at path: \(track.path)")
        }
        
        do {
            let artworkURL = documentsDirectory.appendingPathComponent(track.artwork)
            let smallArtworkURL = documentsDirectory.appendingPathComponent(track.smallArtwork)
            if fileManager.fileExists(atPath: artworkURL.path) {
                try fileManager.removeItem(at: artworkURL)
                try fileManager.removeItem(at: smallArtworkURL)
            }
        } catch {
            print("Failed to delete file at path: \(track.artwork)")
            print("Failed to delete file at path: \(track.smallArtwork)")
        }
    }
}
