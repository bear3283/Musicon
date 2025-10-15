//
//  SetlistSongsSection.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct SetlistSongsSection: View {
    @Environment(\.modelContext) private var modelContext
    let setlist: Setlist
    @Binding var showingAddSong: Bool
    @State private var editingItem: SetlistItem?

    var sortedItems: [SetlistItem] {
        setlist.items.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("곡 목록")
                .font(.headline)

            if sortedItems.isEmpty {
                // 빈 상태
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("곡이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("곡을 추가하여 콘티를 구성하세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // 곡 목록
                VStack(spacing: 8) {
                    ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                        Button {
                            editingItem = item
                        } label: {
                            SetlistSongRow(index: index + 1, item: item, onDelete: {
                                deleteItem(item)
                            })
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { from, to in
                        moveItem(from: from, to: to)
                    }
                }
            }

            // 곡 추가 버튼
            Button {
                showingAddSong = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("곡 추가")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $editingItem) { item in
            SetlistItemDetailView(item: item)
        }
    }

    private func moveItem(from: IndexSet, to: Int) {
        var items = sortedItems
        items.move(fromOffsets: from, toOffset: to)

        // 순서 재정렬
        for (index, item) in items.enumerated() {
            item.order = index
        }

        setlist.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteItem(_ item: SetlistItem) {
        if let index = setlist.items.firstIndex(where: { $0.id == item.id }) {
            setlist.items.remove(at: index)
            modelContext.delete(item)

            // 순서 재정렬
            for (index, item) in sortedItems.enumerated() {
                item.order = index
            }

            setlist.updatedAt = Date()
            try? modelContext.save()
        }
    }
}

struct SetlistSongRow: View {
    let index: Int
    let item: SetlistItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 순서 번호
            Text("\(index)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 30)

            // 곡 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let key = item.key {
                        Text(key)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if let tempo = item.tempo {
                        Text("\(tempo) BPM")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if let timeSignature = item.timeSignature {
                        Text(timeSignature)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if item.notes != nil {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // 삭제 버튼
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SetlistSongsSection(
        setlist: Setlist(title: "Test"),
        showingAddSong: .constant(false)
    )
    .padding()
    .modelContainer(for: Setlist.self, inMemory: true)
}
