//
//  SetlistItemDetailView.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct SetlistItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let item: SetlistItem

    @State private var isEditing = true

    var song: Song {
        item.song
    }

    var sortedItems: [SetlistItem] {
        item.setlist?.items.sorted { $0.order < $1.order } ?? []
    }

    var currentOrder: Int {
        sortedItems.firstIndex(where: { $0.id == item.id }).map { $0 + 1 } ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 순서 정보
                    SetlistItemOrderSection(
                        order: currentOrder,
                        total: sortedItems.count
                    )

                    Divider()

                    // 곡 정보 섹션 (커스텀 설정 가능)
                    SetlistItemInfoSection(item: item, isEditing: $isEditing)

                    Divider()

                    // 곡 구조 섹션
                    SongStructureSection(song: song, isEditing: .constant(false))

                    Divider()

                    // 악보 섹션
                    SheetMusicSection(song: song)

                    Divider()

                    // 콘티 메모 섹션
                    SetlistItemNotesSection(item: item)
                }
                .padding(horizontalSizeClass == .regular ? 32 : 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(song.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 순서 정보 섹션
struct SetlistItemOrderSection: View {
    let order: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("순서")
                .font(.headline)

            HStack {
                Text("\(order) / \(total)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// 곡 정보 및 커스텀 설정 섹션
struct SetlistItemInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    let item: SetlistItem
    @Binding var isEditing: Bool

    @State private var editedKey: String = ""
    @State private var editedTempo: Int = 120
    @State private var useCustomKey = false
    @State private var useCustomTempo = false

    let keys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))

    var song: Song {
        item.song
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("곡 정보")
                .font(.headline)

            // 기본 정보 표시
            VStack(spacing: 12) {
                // 코드 설정
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("코드")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Toggle("커스텀 코드 사용", isOn: $useCustomKey)
                        .onChange(of: useCustomKey) { _, newValue in
                            if newValue {
                                editedKey = song.key ?? "C"
                            }
                            saveChanges()
                        }

                    if useCustomKey {
                        HStack(spacing: 0) {
                            Picker("코드", selection: $editedKey) {
                                ForEach(keys, id: \.self) { keyOption in
                                    Text(keyOption).tag(keyOption)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .onChange(of: editedKey) { _, _ in
                                saveChanges()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        HStack {
                            Text("원곡 코드:")
                                .foregroundStyle(.secondary)
                            Text(song.key ?? "-")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // 템포 설정
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("템포")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Toggle("커스텀 템포 사용", isOn: $useCustomTempo)
                        .onChange(of: useCustomTempo) { _, newValue in
                            if newValue {
                                editedTempo = song.tempo ?? 120
                            }
                            saveChanges()
                        }

                    if useCustomTempo {
                        HStack(spacing: 0) {
                            Picker("템포", selection: $editedTempo) {
                                ForEach(tempoOptions, id: \.self) { bpm in
                                    Text("\(bpm)").tag(bpm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .onChange(of: editedTempo) { _, _ in
                                saveChanges()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        HStack {
                            Text("원곡 템포:")
                                .foregroundStyle(.secondary)
                            Text(song.tempo != nil ? "\(song.tempo!) BPM" : "-")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // 박자 정보
                HStack {
                    Text("박자:")
                        .foregroundStyle(.secondary)
                    Text(song.timeSignature ?? "-")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        if let customKeyValue = item.customKey {
            editedKey = customKeyValue
            useCustomKey = true
        } else {
            editedKey = song.key ?? "C"
            useCustomKey = false
        }

        if let customTempoValue = item.customTempo {
            editedTempo = customTempoValue
            useCustomTempo = true
        } else {
            editedTempo = song.tempo ?? 120
            useCustomTempo = false
        }
    }

    private func saveChanges() {
        item.customKey = useCustomKey ? editedKey : nil
        item.customTempo = useCustomTempo ? editedTempo : nil
        item.setlist?.updatedAt = Date()
        try? modelContext.save()
    }
}

// 콘티 메모 섹션
struct SetlistItemNotesSection: View {
    @Environment(\.modelContext) private var modelContext
    let item: SetlistItem

    @State private var notes: String = ""
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("콘티 메모")
                .font(.headline)

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .focused($isNotesFocused)
                .onChange(of: isNotesFocused) { _, isFocused in
                    if !isFocused {
                        saveNotes()
                    }
                }
        }
        .onAppear {
            notes = item.notes ?? ""
        }
    }

    private func saveNotes() {
        item.notes = notes.isEmpty ? nil : notes
        item.setlist?.updatedAt = Date()
        try? modelContext.save()
    }
}

#Preview {
    SetlistItemDetailView(
        item: SetlistItem(
            order: 0,
            song: Song(title: "Amazing Grace", tempo: 120, key: "C", timeSignature: "4/4")
        )
    )
    .modelContainer(for: [Song.self, Setlist.self], inMemory: true)
}
