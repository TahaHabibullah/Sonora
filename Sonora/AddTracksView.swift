//
//  AddTracksView.swift
//  Sonora
//
//  Created by Taha Habibullah on 2/1/25.
//

import SwiftUI
import AVFoundation

struct AddTracksView: View {
    @Binding var isPresented: Bool
    @State var selectedFiles: [URL]
    @State private var isFilePickerPresented = false
    @State private var isImagePickerPresented = false
    
    var body: some View {
        NavigationView {
            GeometryReader { _ in
                VStack {
                    List {
                        ForEach(Array(selectedFiles.enumerated()), id: \.element) { index, element in
                            HStack {
                                Text(element.deletingPathExtension().lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text("\(index+1)")
                                    .foregroundColor(.gray)
                            }
                            .padding([.leading, .trailing])
                            .listRowInsets(EdgeInsets())
                        }
                        .onDelete(perform: deleteFile)
                    }
                    .listStyle(PlainListStyle())
                    
                    Spacer()
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isFilePickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Files")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(.blue)
                        .cornerRadius(8)
                    }
                    .padding()
                }
                .padding(.top, 5)
                .navigationTitle("\(selectedFiles.count) Files Selected")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue),
                    trailing: Button("Save") {
                        if !selectedFiles.isEmpty {
                            let trackPaths = copyFilesToDocuments(sourceURLs: selectedFiles)
                            for trackPath in trackPaths {
                                let track = Track(artist: "Unknown Artist", artwork: nil, path: trackPath)
                                TrackManager.shared.saveTrack(track)
                            }
                        }
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
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
        selectedFiles.remove(atOffsets: offsets)
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
    
    private func directoryExists(at path: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    private func copyFilesToDocuments(sourceURLs: [URL]) -> [String] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let looseTracksDirectory = documentsURL.appendingPathComponent("Loose_Tracks")
        var filePaths: [String] = []
        
        
        if !directoryExists(at: looseTracksDirectory) {
            do {
                try fileManager.createDirectory(at: looseTracksDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
            }
        }
        
        for sourceURL in sourceURLs {
            var destinationURL = looseTracksDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            var count = 1
            while fileManager.fileExists(atPath: destinationURL.path) {
                if count > 1 {
                    let newDestinationURL = destinationURL.path.replacingOccurrences(
                        of: "\(sourceURL.deletingPathExtension().lastPathComponent)__\(count-1)",
                        with: "\(sourceURL.deletingPathExtension().lastPathComponent)__\(count)")
                    destinationURL = URL(fileURLWithPath: newDestinationURL)
                }
                else {
                    let newDestinationURL = destinationURL.path.replacingOccurrences(
                        of: "\(sourceURL.deletingPathExtension().lastPathComponent)",
                        with: "\(sourceURL.deletingPathExtension().lastPathComponent)__1")
                    destinationURL = URL(fileURLWithPath: newDestinationURL)
                }
                count+=1
            }
            
            var filePath = ""
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            if count > 1 {
                filePath = "Loose_Tracks/\(title)__\(count-1).\(ext)"
            }
            else {
                filePath = "Loose_Tracks/\(title).\(ext)"
            }
        
            do {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                filePaths.append(filePath)
            } catch {
                print("Unable to copy file: \(error.localizedDescription)")
            }
        }
        return filePaths
    }
}
