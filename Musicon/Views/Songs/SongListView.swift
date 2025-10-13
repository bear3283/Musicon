//
//  SongListView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct SongListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var searchText = ""
    @State private var showingCreateSheet = false

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.title.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSongs.isEmpty {
                    ContentUnavailableView {
                        Label("곡이 없습니다", systemImage: "music.note")
                    } description: {
                        Text("+ 버튼을 눌러 첫 곡을 추가해보세요")
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            NavigationLink(value: song) {
                                SongRowView(song: song)
                            }
                        }
                        .onDelete(perform: deleteSongs)
                    }
                }
            }
            .navigationTitle("곡 목록")
            .searchable(text: $searchText, prompt: "곡 검색")
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSongView()
            }
        }
    }

    private func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            let song = filteredSongs[index]
            modelContext.delete(song)
        }
    }
}

struct SongRowView: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.headline)

            HStack {
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
        .padding(.vertical, 4)
    }
}

struct CreateSongView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var key = "C"
    @State private var tempo = 120
    @State private var timeSignature = "4/4"

    let keys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
        "Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "A#m", "Bm"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("곡 제목", text: $title)
                }

                Section("음악 정보") {
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("키")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("키", selection: $key) {
                                ForEach(keys, id: \.self) { keyOption in
                                    Text(keyOption).tag(keyOption)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("템포 (BPM)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("템포", selection: $tempo) {
                                ForEach(tempoOptions, id: \.self) { bpm in
                                    Text("\(bpm)").tag(bpm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("박자")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("박자", selection: $timeSignature) {
                                ForEach(timeSignatures, id: \.self) { signature in
                                    Text(signature).tag(signature)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 140)
                }
            }
            .navigationTitle("새 곡 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSong()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addSong() {
        let song = Song(
            title: title,
            tempo: tempo,
            key: key,
            timeSignature: timeSignature
        )

        modelContext.insert(song)
        dismiss()
    }
}

#Preview {
    SongListView()
        .modelContainer(for: Song.self, inMemory: true)
}
