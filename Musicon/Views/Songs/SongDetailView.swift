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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let song: Song

    @State private var isEditing = false

    var body: some View {
        ScrollView {
            if horizontalSizeClass == .regular {
                // iPad: 2단 레이아웃
                iPadLayout
            } else {
                // iPhone: 세로 레이아웃
                iPhoneLayout
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
        .tint(.accentGold)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "완료" : "편집") {
                    isEditing.toggle()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.accentGold)
                .accessibilityHint(isEditing ? "편집 모드를 종료합니다" : "편집 모드로 전환하여 곡 정보를 수정할 수 있습니다")
            }
        }
    }

    @ViewBuilder
    private var iPhoneLayout: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 곡 정보 섹션
            SongInfoSection(song: song, isEditing: $isEditing)

            Divider()

            // 곡 구조 섹션
            SongStructureSection(song: song, isEditing: $isEditing)

            Divider()

            // 악보 섹션
            SheetMusicSection(song: song)
        }
        .padding()
    }

    @ViewBuilder
    private var iPadLayout: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 곡 정보 섹션 (전체 너비)
            SongInfoSection(song: song, isEditing: $isEditing)

            Divider()

            // 곡 구조 섹션 (전체 너비)
            SongStructureSection(song: song, isEditing: $isEditing)

            Divider()

            // 악보 섹션 (전체 너비 - 크게 표시)
            SheetMusicSection(song: song)
        }
        .padding(Spacing.xxl)
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
