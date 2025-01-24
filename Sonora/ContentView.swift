//
//  ContentView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Group {
                PlaylistsView()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Playlists")
                    }
                LibraryView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Library")
                    }
            }
            .accentColor(.blue)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    MiniPlayer()
                }
            }
        }
    }
}
