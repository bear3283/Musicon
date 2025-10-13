//
//  SetlistDetailView.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let setlist: Setlist

    @State private var isEditing = false
    @State private var showingAddSong = false

    var sortedItems: [SetlistItem] {
        setlist.items.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 콘티 정보 섹션
                SetlistInfoSection(setlist: setlist, isEditing: $isEditing)

                Divider()

                // 곡 목록 섹션
                SetlistSongsSection(setlist: setlist, showingAddSong: $showingAddSong)
            }
            .padding()
        }
        .navigationTitle(setlist.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "완료" : "편집") {
                    isEditing.toggle()
                }
            }
        }
        .sheet(isPresented: $showingAddSong) {
            AddSongToSetlistView(setlist: setlist)
        }
    }
}

#Preview {
    NavigationStack {
        SetlistDetailView(setlist: Setlist(
            title: "주일 예배",
            performanceDate: Date(),
            notes: "테스트 메모"
        ))
    }
    .modelContainer(for: Setlist.self, inMemory: true)
}
