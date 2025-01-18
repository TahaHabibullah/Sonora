//
//  AlbumView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/17/25.
//
import SwiftUI

struct AlbumView: View {
    @State private var isFilePickerPresented = false
    @State private var isEditing = false
    @State private var originalFiles: [URL] = []
    @State var album: Album
    
    var body: some View {
        VStack(spacing: 20) {
            if let artworkData = album.artwork,
               let artwork = UIImage(data: artworkData) {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .gray, radius: 10)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .gray, radius: 10)
            }
            
            Text(album.name)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            
            List {
                ForEach(Array(album.tracks.enumerated()), id: \.element) { index, element in
                    HStack {
                        Text("\(index)")
                            .foregroundColor(.gray)
                        Text(element.deletingPathExtension().lastPathComponent)
                            .padding(.leading, 10)
                        Spacer()
                        Menu {
                            Button(action: {
                            }) {
                                Label("Add to playlist", systemImage: "plus.square")
                            }
                            Button(action: {
                            }) {
                                Label("Rename track", systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
                .onDelete(perform: isEditing ? deleteFile : nil)
                .onMove(perform: isEditing ? moveFile : nil)
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            .listStyle(PlainListStyle())
            .contentMargins(.top, 40)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button(action: {
                        confirmChanges()
                    }) {
                        Text("Done")
                            .foregroundColor(.blue)
                    }
                }
                else {
                    Menu {
                        Button(action: {
                            isFilePickerPresented = true
                        }) {
                            Label("Add files to album", systemImage: "music.note.list")
                        }
                        Button(action: {
                            isEditing = true
                        }) {
                            Label("Edit tracks", systemImage: "pencil")
                        }
                        Button(action: {
                        }) {
                            Label("Delete album", systemImage: "trash.slash")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                            .font(.headline)
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
    }
    
    private func deleteFile(at offsets: IndexSet) {
        album.tracks.remove(atOffsets: offsets)
        if album.tracks.isEmpty {
            isEditing = false
        }
    }
    
    private func confirmChanges() {
        AlbumManager.shared.replaceAlbum(album)
        isEditing = false
    }

    private func moveFile(from source: IndexSet, to destination: Int) {
        album.tracks.move(fromOffsets: source, toOffset: destination)
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            album.tracks.append(contentsOf: urls)
            AlbumManager.shared.replaceAlbum(album)
            
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}
