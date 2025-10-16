//
//  AddSongToSetlistView.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct AddSongToSetlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var selectedSongs: [Song.ID] = []

    var filteredSongs: [Song] {
        let existingSongIDs = Set(setlist.items.compactMap { $0.originalSong?.id })

        let availableSongs = allSongs.filter { !existingSongIDs.contains($0.id) }

        if searchText.isEmpty {
            return availableSongs
        } else {
            return availableSongs.filter { $0.title.localizedStandardContains(searchText) }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if filteredSongs.isEmpty {
                emptyStateView
            } else {
                songListView
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("추가할 곡이 없습니다", systemImage: "music.note")
        } description: {
            if searchText.isEmpty {
                Text("모든 곡이 이미 콘티에 추가되었거나\n곡 목록에 곡이 없습니다")
            } else {
                Text("'\(searchText)'에 해당하는 곡을 찾을 수 없습니다")
            }
        }
    }

    private var songListView: some View {
        List {
            ForEach(filteredSongs) { song in
                songRowButton(for: song)
            }
        }
    }

    private func songRowButton(for song: Song) -> some View {
        Button {
            toggleSongSelection(song)
        } label: {
            songRowContent(for: song)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: song))
        .accessibilityHint(selectedSongs.contains(song.id) ? "선택됨, 선택 해제하려면 누르세요" : "선택하려면 누르세요")
        .accessibilityAddTraits(selectedSongs.contains(song.id) ? [.isSelected] : [])
    }

    private func songRowContent(for song: Song) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.titleSmall)

                HStack(spacing: Spacing.sm) {
                    if let key = song.key {
                        Badge(key, style: .code)
                    }

                    if let tempo = song.tempo {
                        Badge("\(tempo) BPM", style: .tempo)
                    }

                    if let timeSignature = song.timeSignature {
                        Badge(timeSignature, style: .signature)
                    }
                }
            }

            Spacer()

            selectionIndicator(for: song)
        }
    }

    @ViewBuilder
    private func selectionIndicator(for song: Song) -> some View {
        if let index = selectedSongs.firstIndex(of: song.id) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryBlack)
                .frame(width: 24, height: 24)
                .background(Color.accentGold)
                .clipShape(Circle())
        } else {
            Image(systemName: "circle")
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func toggleSongSelection(_ song: Song) {
        if let index = selectedSongs.firstIndex(of: song.id) {
            selectedSongs.remove(at: index)
        } else {
            selectedSongs.append(song.id)
        }
    }

    private func accessibilityLabel(for song: Song) -> String {
        var label = song.title
        if let key = song.key {
            label += ", 코드 \(key)"
        }
        if let tempo = song.tempo {
            label += ", 템포 \(tempo) BPM"
        }
        if let timeSignature = song.timeSignature {
            label += ", 박자 \(timeSignature)"
        }
        return label
    }

    var body: some View {
        NavigationStack {
            contentView
            .navigationTitle("곡 추가")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "곡 검색")
            .tint(.accentGold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가 (\(selectedSongs.count))") {
                        addSongs()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedSongs.isEmpty ? Color.textTertiary : Color.accentGold)
                    .disabled(selectedSongs.isEmpty)
                    .accessibilityLabel("선택한 곡 추가")
                    .accessibilityValue("\(selectedSongs.count)곡 선택됨")
                    .accessibilityHint(selectedSongs.isEmpty ? "먼저 곡을 선택하세요" : "\(selectedSongs.count)곡을 콘티에 추가합니다")
                }
            }
        }
    }

    private func addSongs() {
        // 선택한 순서대로 곡 추가 (원곡 복제)
        for (index, songID) in selectedSongs.enumerated() {
            if let song = allSongs.first(where: { $0.id == songID }) {
                // Song으로부터 데이터를 복제하여 SetlistItem 생성
                let item = SetlistItem(order: setlist.items.count + index, cloneFrom: song)
                item.setlist = setlist

                // 섹션들의 관계 설정
                for section in item.sections {
                    section.setlistItem = item
                    modelContext.insert(section)
                }

                setlist.items.append(item)
                modelContext.insert(item)
            }
        }

        setlist.updatedAt = Date()
        try? modelContext.save()

        dismiss()
    }
}

#Preview {
    AddSongToSetlistView(setlist: Setlist(title: "Test"))
        .modelContainer(for: [Song.self, Setlist.self], inMemory: true)
}
