//
//  ContentView.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
                
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray
        ]
                
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UICollectionView.appearance().contentInset.top = -35
    }
    
    var body: some View {
        TabView {
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
        
    }
}
