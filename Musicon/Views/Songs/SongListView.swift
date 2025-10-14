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
    @State private var songToDelete: Song?

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    songToDelete = song
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: filteredSongs.count)
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
            .alert("곡 삭제", isPresented: Binding(
                get: { songToDelete != nil },
                set: { if !$0 { songToDelete = nil } }
            )) {
                Button("취소", role: .cancel) {
                    songToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let song = songToDelete {
                        modelContext.delete(song)
                        songToDelete = nil
                    }
                }
            } message: {
                if let song = songToDelete {
                    Text("'\(song.title)'을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
                }
            }
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

                if let timeSignature = song.timeSignature {
                    Text(timeSignature)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
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

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    let keys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
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
                            Text("코드")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("코드", selection: $key) {
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("유효성 검사 오류", isPresented: $showingValidationError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    private func addSong() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationErrorMessage = "제목을 입력해주세요"
            showingValidationError = true
            return
        }

        guard tempo > 0 && tempo <= 300 else {
            validationErrorMessage = "올바른 BPM을 입력해주세요 (1-300)"
            showingValidationError = true
            return
        }

        let song = Song(
            title: trimmedTitle,
            tempo: tempo,
            key: key,
            timeSignature: timeSignature
        )

        do {
            try song.validate()
            modelContext.insert(song)
            dismiss()
        } catch let error as ValidationError {
            validationErrorMessage = error.errorDescription ?? "알 수 없는 오류가 발생했습니다"
            showingValidationError = true
        } catch {
            validationErrorMessage = "곡 추가에 실패했습니다"
            showingValidationError = true
        }
    }
}

#Preview {
    SongListView()
        .modelContainer(for: Song.self, inMemory: true)
}
