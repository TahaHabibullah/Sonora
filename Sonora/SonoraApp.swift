//
//  SonoraApp.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI

@main
struct SonoraApp: App {
    @StateObject private var playQueue = PlayQueue()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
                .environmentObject(playQueue)
        }
    }
}
