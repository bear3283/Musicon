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
        GeometryReader { outerGeometry in
            ScrollView {
                if DeviceType.isIPad {
                    // iPad: 2단 레이아웃
                    iPadLayout(screenHeight: outerGeometry.size.height)
                } else {
                    // iPhone: 세로 레이아웃
                    iPhoneLayout(screenHeight: outerGeometry.size.height)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(DeviceType.isIPad ? .inline : .large)
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
    private func iPhoneLayout(screenHeight: CGFloat) -> some View {
        let sheetMusicHeight = max(screenHeight * 0.5, 450)

        VStack(alignment: .leading, spacing: 24) {
            // 곡 정보 섹션
            SongInfoSection(song: song, isEditing: $isEditing)

            Divider()

            // 곡 구조 섹션
            SongStructureSection(song: song, isEditing: $isEditing)

            Divider()

            // 악보 섹션
            GeometryReader { geometry in
                SheetMusicSection(song: song, availableHeight: geometry.size.height * 0.85)
            }
            .frame(height: sheetMusicHeight)
        }
        .padding()
    }

    @ViewBuilder
    private func iPadLayout(screenHeight: CGFloat) -> some View {
        let sheetMusicHeight = max(screenHeight * 0.6, 700)

        VStack(alignment: .leading, spacing: 24) {
            // 곡 정보 섹션 (전체 너비)
            SongInfoSection(song: song, isEditing: $isEditing)

            Divider()

            // 곡 구조 섹션 (전체 너비)
            SongStructureSection(song: song, isEditing: $isEditing)

            Divider()

            // 악보 섹션 (전체 너비 - 크게 표시)
            GeometryReader { geometry in
                SheetMusicSection(song: song, availableHeight: geometry.size.height * 0.92)
            }
            .frame(height: sheetMusicHeight)
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
