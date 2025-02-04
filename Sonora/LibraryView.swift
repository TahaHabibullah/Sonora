//
//  Library.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct LibraryView: View {
    @EnvironmentObject var playQueue: PlayQueue
    @State private var isAddAlbumPresented = false
    @State private var isAddTracksPresented = false
    @State private var isEditTrackPresented = false
    @State private var isFilePickerPresented = false
    @State private var selectedFiles: [URL] = []
    @State private var albums: [Album] = []
    @State private var looseTracks: [Track] = []
    @State private var trackToEdit: Track? = nil
    @State private var selectedTab: Int = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack() {
            NavigationStack {
                Picker(selection: $selectedTab, label: Text("")) {
                    Text("Albums").tag(0)
                    Text("Loose Tracks").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                    
                TabView(selection: $selectedTab,
                    content: {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(albums) { album in
                                NavigationLink(destination: AlbumView(album: album)) {
                                    VStack(spacing: 0) {
                                        if let artwork = Utils.shared.loadImageFromDocuments(filePath: album.artwork) {
                                            Image(uiImage: artwork)
                                                .resizable()
                                                .scaledToFit()
                                                .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                        } else {
                                            Image(systemName: "music.note.list")
                                                .font(.title)
                                                .frame(width: 178, height: 178)
                                                .background(Color.black)
                                                .foregroundColor(.gray)
                                                .border(.gray, width: 1)
                                                .shadow(color: Color.gray.opacity(0.5), radius: 10)
                                        }
                                        VStack(spacing: 0) {
                                            if !album.name.isEmpty {
                                                Text(album.name)
                                                    .foregroundColor(.white)
                                                    .font(.subheadline)
                                                    .bold()
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            else {
                                                Text("Untitled Album")
                                                    .foregroundColor(.white)
                                                    .font(.subheadline)
                                                    .bold()
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            if !album.artist.isEmpty {
                                                Text(album.artist)
                                                    .foregroundColor(.gray)
                                                    .font(.subheadline)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            else {
                                                Text("Unknown Artist")
                                                    .foregroundColor(.gray)
                                                    .font(.subheadline)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 50)
                    }
                    .tag(0)
                    
                    ScrollView {
                        LazyVStack {
                            List {
                                ForEach(looseTracks) { track in
                                    Button(action: {
                                        playQueue.startQueue(from: track, in: looseTracks)
                                    }) {
                                        HStack {
                                            if let artwork = Utils.shared.loadImageFromDocuments(filePath: track.artwork) {
                                                Image(uiImage: artwork)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                            }
                                            else {
                                                Image(systemName: "music.note.list")
                                                    .font(.subheadline)
                                                    .frame(width: 50, height: 50)
                                                    .background(Color.gray.opacity(0.5))
                                            }
                                            VStack(spacing: 0) {
                                                HStack {
                                                    Text(track.title)
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text(track.artist)
                                                        .foregroundColor(.gray)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                            }
                                            Spacer()
                                            Text(getTrackDuration(from: track.path))
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                    
                                            Menu {
                                                Button(action: {
                                                }) {
                                                    Label("Add To Playlist", systemImage: "plus.square")
                                                }
                                                Button(action: {
                                                    trackToEdit = track
                                                    isEditTrackPresented = true
                                                }) {
                                                    Label("Edit Details", systemImage: "pencil")
                                                }
                                                Button(role: .destructive, action: {
                                                    TrackManager.shared.deleteTrack(track)
                                                    looseTracks = TrackManager.shared.fetchTracks()
                                                }) {
                                                    Label("Delete Track", systemImage: "trash")
                                                }
                                            } label: {
                                                HStack {
                                                    Image(systemName: "ellipsis")
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.leading, 10)
                                                .frame(width: 25, height: 25)
                                                .contentShape(Rectangle())
                                            }
                                        }
                                        .frame(height: 40)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: CGFloat(looseTracks.count * 70))
                            .scrollDisabled(true)
                            .listStyle(PlainListStyle())
                        }
                    }
                    .tag(1)
                    .padding(.bottom, 50)
                    
                })
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onAppear {
                    albums = AlbumManager.shared.fetchAlbums()
                    looseTracks = TrackManager.shared.fetchTracks()
                }
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                isAddAlbumPresented = true
                            }) {
                                Label("Create New Album", systemImage: "rectangle.stack.badge.plus")
                            }
                            
                            Button(action: {
                                isFilePickerPresented = true
                            }) {
                                Label("Import Loose Tracks", systemImage: "music.note")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                .font(.title2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: true
                ) { result in
                    handleFileSelection(result: result)
                    isAddTracksPresented = true
                }
                .sheet(isPresented: $isAddAlbumPresented) {
                    AddAlbumView(isPresented: $isAddAlbumPresented)
                        .onDisappear {
                            albums = AlbumManager.shared.fetchAlbums()
                        }
                }
                .sheet(isPresented: $isAddTracksPresented) {
                    AddTracksView(isPresented: $isAddTracksPresented, selectedFiles: selectedFiles)
                        .onDisappear {
                            looseTracks = TrackManager.shared.fetchTracks()
                            selectedFiles.removeAll()
                        }
                }
                .sheet(item: $trackToEdit) { track in
                    EditTrackView(track: track)
                        .onDisappear {
                            looseTracks = TrackManager.shared.fetchTracks()
                        }
                }
            }
        }
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            urls.map { $0.startAccessingSecurityScopedResource() }
            selectedFiles.append(contentsOf: urls)
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    private func getTrackDuration(from path: String) -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let trackURL = documentsDirectory.appendingPathComponent(path)
        
        let asset = AVURLAsset(url: trackURL)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        if durationInSeconds.isFinite {
            let minutes = Int(durationInSeconds) / 60
            let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
            let stringSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "\(minutes):\(stringSeconds)"
        }
        else {
            return ""
        }
    }
    
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var selectedImage: UIImage?

        init(selectedImage: Binding<UIImage?>) {
            _selectedImage = selectedImage
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            selectedImage = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
