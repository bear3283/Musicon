//
//  SongDetailView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct SongDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let song: Song

    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 곡 정보 섹션
                SongInfoSection(song: song, isEditing: $isEditing)

                Divider()

                // 곡 구조 섹션
                SongStructureSection(song: song)

                Divider()

                // 악보 섹션
                SheetMusicSection(song: song)
            }
            .padding()
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "완료" : "편집") {
                    isEditing.toggle()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SongDetailView(song: Song(
            title: "Amazing Grace",
            tempo: 120,
            key: "C",
            timeSignature: "4/4"
        ))
    }
    .modelContainer(for: Song.self, inMemory: true)
}
