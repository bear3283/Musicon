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
    @State private var showingCreateSheet = false
    @State private var showingFilterSheet = false
    @State private var songToDelete: Song?

    // 필터 상태
    @State private var selectedKeys: Set<String> = []
    @State private var minTempo: Int?
    @State private var maxTempo: Int?
    @State private var selectedTimeSignatures: Set<String> = []

    var filteredSongs: [Song] {
        var result = songs

        // 코드 필터
        if !selectedKeys.isEmpty {
            result = result.filter { song in
                if let key = song.key {
                    return selectedKeys.contains(key)
                }
                return false
            }
        }

        // 템포 필터
        if let minTempo = minTempo {
            result = result.filter { song in
                if let tempo = song.tempo {
                    return tempo >= minTempo
                }
                return false
            }
        }

        if let maxTempo = maxTempo {
            result = result.filter { song in
                if let tempo = song.tempo {
                    return tempo <= maxTempo
                }
                return false
            }
        }

        // 박자 필터
        if !selectedTimeSignatures.isEmpty {
            result = result.filter { song in
                if let timeSignature = song.timeSignature {
                    return selectedTimeSignatures.contains(timeSignature)
                }
                return false
            }
        }

        return result
    }

    var hasActiveFilters: Bool {
        !selectedKeys.isEmpty || minTempo != nil || maxTempo != nil || !selectedTimeSignatures.isEmpty
    }

    var availableKeys: [String] {
        Array(Set(songs.compactMap { $0.key })).sorted()
    }

    var availableTimeSignatures: [String] {
        Array(Set(songs.compactMap { $0.timeSignature })).sorted()
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
            .tint(Color.accentGold)
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? Color.accentGold : Color.textSecondary)
                    }
                    .accessibilityLabel("필터")
                    .accessibilityHint(hasActiveFilters ? "활성화된 필터가 있습니다. 필터를 변경하거나 제거할 수 있습니다" : "곡 목록을 필터링합니다")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentGold)
                    }
                    .accessibilityLabel("새 곡 추가")
                    .accessibilityHint("새로운 곡을 추가합니다")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSongView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                SongFilterView(
                    selectedKeys: $selectedKeys,
                    minTempo: $minTempo,
                    maxTempo: $maxTempo,
                    selectedTimeSignatures: $selectedTimeSignatures,
                    availableKeys: availableKeys,
                    availableTimeSignatures: availableTimeSignatures,
                    onReset: {
                        selectedKeys.removeAll()
                        minTempo = nil
                        maxTempo = nil
                        selectedTimeSignatures.removeAll()
                    }
                )
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

    var accessibilityDescription: String {
        var description = song.title

        var details: [String] = []
        if let key = song.key {
            details.append("코드 \(key)")
        }
        if let tempo = song.tempo {
            details.append("템포 \(tempo) BPM")
        }
        if let timeSignature = song.timeSignature {
            details.append("박자 \(timeSignature)")
        }

        if !details.isEmpty {
            description += ", " + details.joined(separator: ", ")
        }

        return description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(song.title)
                .font(.titleSmall)
                .foregroundStyle(Color.textPrimary)

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
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("곡 상세 정보를 확인합니다")
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
                        .accessibilityLabel("곡 제목")
                        .accessibilityHint("곡의 이름을 입력하세요")
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
                            .accessibilityLabel("코드")
                            .accessibilityValue(key)
                            .accessibilityHint("곡의 코드를 선택하세요")
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
                            .accessibilityLabel("템포")
                            .accessibilityValue("\(tempo) BPM")
                            .accessibilityHint("곡의 템포를 선택하세요")
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
                            .accessibilityLabel("박자")
                            .accessibilityValue(timeSignature)
                            .accessibilityHint("곡의 박자를 선택하세요")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 140)
                }
            }
            .navigationTitle("새 곡 추가")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.accentGold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSong()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.textTertiary : Color.accentGold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityHint(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "곡 제목을 먼저 입력하세요" : "새 곡을 추가합니다")
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

struct SongFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedKeys: Set<String>
    @Binding var minTempo: Int?
    @Binding var maxTempo: Int?
    @Binding var selectedTimeSignatures: Set<String>

    let availableKeys: [String]
    let availableTimeSignatures: [String]
    let onReset: () -> Void

    @State private var minTempoText = ""
    @State private var maxTempoText = ""

    var body: some View {
        NavigationStack {
            Form {
                // 코드 필터
                if !availableKeys.isEmpty {
                    Section {
                        ForEach(availableKeys, id: \.self) { key in
                            Toggle(isOn: Binding(
                                get: { selectedKeys.contains(key) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedKeys.insert(key)
                                    } else {
                                        selectedKeys.remove(key)
                                    }
                                }
                            )) {
                                HStack {
                                    Text(key)
                                        .font(.body)
                                    Spacer()
                                    Text(key)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } header: {
                        Text("코드")
                    }
                }

                // 템포 필터
                Section {
                    HStack {
                        Text("최소")
                        TextField("BPM", text: $minTempoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: minTempoText) { _, newValue in
                                minTempo = Int(newValue)
                            }
                    }

                    HStack {
                        Text("최대")
                        TextField("BPM", text: $maxTempoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: maxTempoText) { _, newValue in
                                maxTempo = Int(newValue)
                            }
                    }
                } header: {
                    Text("템포 (BPM)")
                }

                // 박자 필터
                if !availableTimeSignatures.isEmpty {
                    Section {
                        ForEach(availableTimeSignatures, id: \.self) { signature in
                            Toggle(isOn: Binding(
                                get: { selectedTimeSignatures.contains(signature) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedTimeSignatures.insert(signature)
                                    } else {
                                        selectedTimeSignatures.remove(signature)
                                    }
                                }
                            )) {
                                HStack {
                                    Text(signature)
                                        .font(.body)
                                    Spacer()
                                    Text(signature)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } header: {
                        Text("박자")
                    }
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.accentGold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("초기화") {
                        onReset()
                        minTempoText = ""
                        maxTempoText = ""
                    }
                    .foregroundStyle(Color.textSecondary)
                    .disabled(selectedKeys.isEmpty && minTempo == nil && maxTempo == nil && selectedTimeSignatures.isEmpty)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentGold)
                }
            }
            .onAppear {
                if let minTempo = minTempo {
                    minTempoText = "\(minTempo)"
                }
                if let maxTempo = maxTempo {
                    maxTempoText = "\(maxTempo)"
                }
            }
        }
    }
}

#Preview {
    SongListView()
        .modelContainer(for: Song.self, inMemory: true)
}
