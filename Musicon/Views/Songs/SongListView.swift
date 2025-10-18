//
//  SongListView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct SongListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var showingCreateSheet = false
    @State private var showingFilterSheet = false
    @State private var songToDelete: Song?
    @State private var searchText = ""

    // 필터 상태
    @State private var selectedKeys: Set<String> = []
    @State private var minTempo: Int?
    @State private var maxTempo: Int?
    @State private var selectedTimeSignatures: Set<String> = []

    var filteredSongs: [Song] {
        var result = songs

        // 검색 필터
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedStandardContains(searchText) ||
                ($0.key?.localizedStandardContains(searchText) ?? false) ||
                ($0.tempo != nil && "\($0.tempo!)".contains(searchText)) ||
                ($0.timeSignature?.localizedStandardContains(searchText) ?? false)
            }
        }

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
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentGold)
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
                        Image(systemName: "plus.circle")
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

    // 곡 구조
    @State private var sections: [TempSection] = []
    @State private var showingAddSection = false
    @State private var editingSection: TempSection?
    @State private var deletingSection: TempSection?

    // 악보
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var sheetMusicImages: [Data] = []
    @State private var showAddImageOptions = false
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    @State private var isLoadingImages = false
    @State private var showingImageLimitError = false

    // 메모
    @State private var notes = ""
    @FocusState private var isNotesFocused: Bool

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    let keys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var sortedSections: [TempSection] {
        sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 기본 정보
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("기본 정보")
                            .font(.titleMedium)

                        TextField("곡 제목", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("곡 제목")
                            .accessibilityHint("곡의 이름을 입력하세요")
                    }

                    Divider()

                    // 음악 정보
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("음악 정보")
                            .font(.titleMedium)

                        HStack(spacing: 0) {
                            VStack(spacing: Spacing.xs) {
                                Text("코드")
                                    .font(.labelSmall)
                                    .foregroundStyle(.secondary)

                                Picker("코드", selection: $key) {
                                    ForEach(keys, id: \.self) { keyOption in
                                        Text(keyOption).tag(keyOption)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .accessibilityLabel("코드")
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: Spacing.xs) {
                                Text("템포")
                                    .font(.labelSmall)
                                    .foregroundStyle(.secondary)

                                Picker("템포", selection: $tempo) {
                                    ForEach(tempoOptions, id: \.self) { bpm in
                                        Text("\(bpm)").tag(bpm)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .accessibilityLabel("템포")
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: Spacing.xs) {
                                Text("박자")
                                    .font(.labelSmall)
                                    .foregroundStyle(.secondary)

                                Picker("박자", selection: $timeSignature) {
                                    ForEach(timeSignatures, id: \.self) { signature in
                                        Text(signature).tag(signature)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .accessibilityLabel("박자")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 120)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }

                    Divider()

                    // 곡 구조
                    structureSection

                    Divider()

                    // 악보
                    sheetMusicSection

                    Divider()

                    // 메모
                    notesSection
                }
                .padding()
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

    // MARK: - Section Views

    var structureSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: 20) {
                Text("구조")
                    .font(.titleMedium)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(SectionType.allCases) { type in
                            Button {
                                if type == .custom {
                                    showingAddSection = true
                                } else {
                                    addQuickSection(type: type)
                                }
                            } label: {
                                Group {
                                    if type == .custom {
                                        Image(systemName: "pencil")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                    } else {
                                        Text(type.rawValue)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .foregroundStyle(Color.accentGold)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.accentGold.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if sortedSections.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("섹션을 추가하여 곡의 구조를 만들어보세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                FlowLayout(spacing: Spacing.md) {
                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                        HStack(spacing: Spacing.sm) {
                            Button {
                                editingSection = section
                            } label: {
                                // TempSection의 type은 옵셔널이 아니므로 그대로 사용
                                Text(section.displayLabel)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(section.type.color)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(section.type.color.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            }
                            .buttonStyle(.plain)

                            Button {
                                deletingSection = section
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)

                            if index < sortedSections.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .sheet(isPresented: $showingAddSection) {
            CreateSectionView(sections: $sections)
        }
        .sheet(item: $editingSection) { section in
            EditTempSectionView(section: section, sections: $sections)
        }
        .alert("섹션 삭제", isPresented: Binding(
            get: { deletingSection != nil },
            set: { if !$0 { deletingSection = nil } }
        )) {
            Button("취소", role: .cancel) {
                deletingSection = nil
            }
            Button("삭제", role: .destructive) {
                if let section = deletingSection {
                    sections.removeAll { $0.id == section.id }
                    // 순서 재정렬
                    for (index, sec) in sortedSections.enumerated() {
                        if let idx = sections.firstIndex(where: { $0.id == sec.id }) {
                            sections[idx].order = index
                        }
                    }
                    deletingSection = nil
                }
            }
        } message: {
            Text("이 섹션을 삭제하시겠습니까?")
        }
    }

    var sheetMusicSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("악보")
                .font(.titleMedium)

            if sheetMusicImages.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("악보 이미지를 추가할 수 있습니다")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(Array(sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            sheetMusicImages.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.red))
                                        }
                                        .padding(4)
                                    }
                            }
                        }
                    }
                }
            }

            Button {
                showAddImageOptions = true
            } label: {
                HStack {
                    if isLoadingImages {
                        ProgressView()
                        Text("이미지 로딩 중...")
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("악보 추가")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentGold.opacity(0.1))
                .foregroundStyle(Color.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .disabled(isLoadingImages)
        }
        .confirmationDialog("악보 이미지 추가", isPresented: $showAddImageOptions) {
            Button("사진 라이브러리에서 선택") {
                showPhotosPicker = true
            }
            Button("파일에서 선택") {
                showFileImporter = true
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $showPhotosPicker) {
            CreatePhotoPickerView(selectedItems: $selectedItems, sheetMusicImages: $sheetMusicImages, isLoadingImages: $isLoadingImages, showingImageLimitError: $showingImageLimitError)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await loadImagesFromFiles(result: result)
            }
        }
        .alert("이미지 제한 초과", isPresented: $showingImageLimitError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("악보 이미지는 최대 10장까지 추가할 수 있습니다.")
        }
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("메모")
                .font(.titleMedium)

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .focused($isNotesFocused)
        }
    }

    // MARK: - Functions

    private func addQuickSection(type: SectionType) {
        let section = TempSection(
            type: type,
            order: sections.count,
            customLabel: nil,
            customName: nil
        )
        sections.append(section)
    }

    private func loadImagesFromFiles(result: Result<[URL], Error>) async {
        guard let urls = try? result.get() else { return }

        await MainActor.run {
            isLoadingImages = true
        }

        for url in urls {
            if sheetMusicImages.count >= 10 {
                await MainActor.run {
                    showingImageLimitError = true
                }
                break
            }

            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            if let data = try? Data(contentsOf: url) {
                await MainActor.run {
                    sheetMusicImages.append(data)
                }
            }
        }

        await MainActor.run {
            isLoadingImages = false
        }
    }

    private func addSong() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationErrorMessage = "제목을 입력해주세요"
            showingValidationError = true
            return
        }

        let song = Song(
            title: trimmedTitle,
            tempo: tempo,
            key: key,
            timeSignature: timeSignature
        )

        // 섹션 추가
        if !sortedSections.isEmpty {
            // 옵셔널 배열 초기화
            if song.sections == nil {
                song.sections = []
            }

            for tempSection in sortedSections {
                let section = SongSection(
                    type: tempSection.type,
                    order: tempSection.order,
                    customLabel: tempSection.customLabel,
                    customName: tempSection.customName
                )
                section.song = song
                song.sections?.append(section)
                modelContext.insert(section)
            }
        }

        // 악보 추가
        song.sheetMusicImages = sheetMusicImages

        // 메모 추가
        if !notes.isEmpty {
            song.notes = notes
        }

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

// MARK: - TempSection

struct TempSection: Identifiable {
    let id = UUID()
    var type: SectionType
    var order: Int
    var customLabel: String?
    var customName: String?

    var displayLabel: String {
        let baseName = type == .custom && customName != nil && !customName!.isEmpty ? customName! : type.rawValue

        if let customLabel = customLabel, !customLabel.isEmpty {
            return "\(baseName)\(customLabel)"
        }
        return baseName
    }
}

// MARK: - Create Section View

struct CreateSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sections: [TempSection]

    @State private var customName: String = ""
    @State private var customLabel: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("커스텀 이름") {
                    TextField("예: Drop, Tag, Vamp...", text: $customName)
                        .autocapitalization(.none)
                }

                Section("번호 (선택사항)") {
                    TextField("예: 1, 2, 3...", text: $customLabel)
                        .keyboardType(.numberPad)
                }

                Section {
                    HStack {
                        Text("표시될 이름:")
                        Spacer()
                        Text(previewLabel)
                            .font(.headline)
                            .foregroundStyle(Color.accentGold)
                    }
                } header: {
                    Text("미리보기")
                }
            }
            .navigationTitle("섹션 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSection()
                    }
                }
            }
        }
    }

    private var previewLabel: String {
        let baseName = !customName.isEmpty ? customName : "Custom"

        if customLabel.isEmpty {
            return baseName
        } else {
            return "\(baseName)\(customLabel)"
        }
    }

    private func addSection() {
        let section = TempSection(
            type: .custom,
            order: sections.count,
            customLabel: customLabel.isEmpty ? nil : customLabel,
            customName: customName.isEmpty ? nil : customName
        )
        sections.append(section)
        dismiss()
    }
}

// MARK: - Edit Temp Section View

struct EditTempSectionView: View {
    @Environment(\.dismiss) private var dismiss
    let section: TempSection
    @Binding var sections: [TempSection]

    @State private var selectedType: SectionType = .verse
    @State private var customLabel: String = ""
    @State private var customName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("섹션 타입") {
                    Picker("타입", selection: $selectedType) {
                        ForEach(SectionType.allCases) { type in
                            Text("\(type.displayName) (\(type.rawValue))").tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if selectedType == .custom {
                    Section("커스텀 이름") {
                        TextField("예: Drop, Tag, Vamp...", text: $customName)
                            .autocapitalization(.none)
                    }
                }

                Section("번호 (선택사항)") {
                    TextField("예: 1, 2, 3...", text: $customLabel)
                        .keyboardType(.numberPad)
                }

                Section {
                    HStack {
                        Text("표시될 이름:")
                        Spacer()
                        Text(previewLabel)
                            .font(.headline)
                            .foregroundStyle(Color.accentGold)
                    }
                } header: {
                    Text("미리보기")
                }
            }
            .navigationTitle("섹션 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        saveSection()
                    }
                }
            }
            .onAppear {
                selectedType = section.type
                customLabel = section.customLabel ?? ""
                customName = section.customName ?? ""
            }
        }
    }

    private var previewLabel: String {
        let baseName = selectedType == .custom && !customName.isEmpty ? customName : selectedType.rawValue

        if customLabel.isEmpty {
            return baseName
        } else {
            return "\(baseName)\(customLabel)"
        }
    }

    private func saveSection() {
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            sections[index].type = selectedType
            sections[index].customLabel = customLabel.isEmpty ? nil : customLabel
            sections[index].customName = customName.isEmpty ? nil : customName
        }
        dismiss()
    }
}

// MARK: - Create Photo Picker View

struct CreatePhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var sheetMusicImages: [Data]
    @Binding var isLoadingImages: Bool
    @Binding var showingImageLimitError: Bool

    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentGold)

                        Text("사진 선택")
                            .font(.headline)

                        Text("최대 10장까지 선택 가능합니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("사진 라이브러리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                if !newItems.isEmpty {
                    Task {
                        await loadImages(from: newItems)
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        await MainActor.run {
            isLoadingImages = true
        }

        for item in items {
            if sheetMusicImages.count >= 10 {
                await MainActor.run {
                    showingImageLimitError = true
                }
                break
            }

            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    sheetMusicImages.append(data)
                }
            }
        }

        await MainActor.run {
            selectedItems = []
            isLoadingImages = false
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
                                        .background(Color.codeBlue.opacity(0.2))
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
                                        .background(Color.signatureOrange.opacity(0.2))
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
