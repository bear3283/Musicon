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
    @State private var selectedSongs: Set<Song.ID> = []

    var filteredSongs: [Song] {
        let existingSongIDs = Set(setlist.items.map { $0.song.id })

        let availableSongs = allSongs.filter { !existingSongIDs.contains($0.id) }

        if searchText.isEmpty {
            return availableSongs
        } else {
            return availableSongs.filter { $0.title.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSongs.isEmpty {
                    ContentUnavailableView {
                        Label("추가할 곡이 없습니다", systemImage: "music.note")
                    } description: {
                        if searchText.isEmpty {
                            Text("모든 곡이 이미 콘티에 추가되었거나\n곡 목록에 곡이 없습니다")
                        } else {
                            Text("'\(searchText)'에 해당하는 곡을 찾을 수 없습니다")
                        }
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            Button {
                                if selectedSongs.contains(song.id) {
                                    selectedSongs.remove(song.id)
                                } else {
                                    selectedSongs.insert(song.id)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(.headline)

                                        HStack(spacing: 8) {
                                            if let key = song.key {
                                                Text(key)
                                                    .font(.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.blue.opacity(0.2))
                                                    .clipShape(Capsule())
                                            }

                                            if let tempo = song.tempo {
                                                Text("\(tempo) BPM")
                                                    .font(.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.green.opacity(0.2))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }

                                    Spacer()

                                    if selectedSongs.contains(song.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("곡 추가")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "곡 검색")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가 (\(selectedSongs.count))") {
                        addSongs()
                    }
                    .disabled(selectedSongs.isEmpty)
                }
            }
        }
    }

    private func addSongs() {
        let songsToAdd = allSongs.filter { selectedSongs.contains($0.id) }

        for (index, song) in songsToAdd.enumerated() {
            let item = SetlistItem(order: setlist.items.count + index, song: song)
            item.setlist = setlist

            setlist.items.append(item)
            modelContext.insert(item)
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
