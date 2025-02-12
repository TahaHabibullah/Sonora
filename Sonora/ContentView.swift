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
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            TabView {
                LibraryView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Library")
                    }
                
                PlaylistsView()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Playlists")
                    }
            }
            .accentColor(.blue)
            
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    MiniPlayer()
                    Divider()
                        .background(.gray)
                }
                .padding(.bottom, 49)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
