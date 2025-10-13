//
//  RootView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            SongListView()
                .tabItem {
                    Label("곡", systemImage: "music.note")
                }

            SetlistListView()
                .tabItem {
                    Label("콘티", systemImage: "music.note.list")
                }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Song.self, Setlist.self], inMemory: true)
}
