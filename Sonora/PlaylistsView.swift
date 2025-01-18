//
//  Playlists.swift
//  Sonora
//
//  Created by Taha Habibullah on 1/15/25.
//

import SwiftUI

struct PlaylistsView: View {
    var body: some View {
        VStack {
            Text("Playlists")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
