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

    var sortedItems: [SetlistItem] {
        item.setlist?.items.sorted { $0.order < $1.order } ?? []
    }

    var currentOrder: Int {
        sortedItems.firstIndex(where: { $0.id == item.id }).map { $0 + 1 } ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 순서 + 곡 정보 (한 행에 배치)
                    SetlistItemOrderAndInfoSection(
                        order: currentOrder,
                        total: sortedItems.count,
                        item: item,
                        isEditing: $isEditing
                    )

                    Divider()

                    // 곡 구조 섹션
                    SetlistItemStructureSection(item: item, isEditing: $isEditing)

                    Divider()

                    // 악보 섹션
                    SetlistItemSheetMusicSection(item: item)

                    Divider()

                    // 콘티 메모 섹션
                    SetlistItemNotesSection(item: item)
                }
                .padding(horizontalSizeClass == .regular ? Spacing.xxl : Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .tint(.accentGold)
        }
    }
}

// 순서 + 곡 정보 통합 섹션
struct SetlistItemOrderAndInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    let order: Int
    let total: Int
    let item: SetlistItem
    @Binding var isEditing: Bool

    @State private var editedKey: String = "C"
    @State private var editedTempo: Int = 120
    @State private var editedTimeSignature: String = "4/4"

    let keys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "Fb", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B", "Cb"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 순서 정보 + 곡 정보 제목 (한 줄)
            HStack(alignment: .center) {
                // 순서
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("순서")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                    Text("\(order) / \(total)")
                        .font(.titleLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentGold)
                }

                Spacer()

                // 곡 정보 레이블
                Text("곡 정보")
                    .font(.titleMedium)
            }

            // 가로 배치된 피커 (축소됨)
            HStack(spacing: 0) {
                VStack(spacing: Spacing.xs) {
                    Text("코드")
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)

                    Picker("코드", selection: $editedKey) {
                        ForEach(keys, id: \.self) { keyOption in
                            Text(keyOption).tag(keyOption)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .tint(.accentGold)
                    .onChange(of: editedKey) { _, _ in
                        saveChanges()
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.xs) {
                    Text("템포")
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)

                    Picker("템포", selection: $editedTempo) {
                        ForEach(tempoOptions, id: \.self) { bpm in
                            Text("\(bpm)").tag(bpm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .tint(.accentGold)
                    .onChange(of: editedTempo) { _, _ in
                        saveChanges()
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.xs) {
                    Text("박자")
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)

                    Picker("박자", selection: $editedTimeSignature) {
                        ForEach(timeSignatures, id: \.self) { signature in
                            Text(signature).tag(signature)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .tint(.accentGold)
                    .onChange(of: editedTimeSignature) { _, _ in
                        saveChanges()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 100)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        editedKey = item.key ?? "C"
        editedTempo = item.tempo ?? 120
        editedTimeSignature = item.timeSignature ?? "4/4"
    }

    private func saveChanges() {
        item.key = editedKey
        item.tempo = editedTempo
        item.timeSignature = editedTimeSignature
        item.setlist?.updatedAt = Date()
        try? modelContext.save()
    }
}

// 곡 정보 편집 섹션
struct SetlistItemInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    let item: SetlistItem
    @Binding var isEditing: Bool

    @State private var editedKey: String = "C"
    @State private var editedTempo: Int = 120
    @State private var editedTimeSignature: String = "4/4"

    let keys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("곡 정보")
                .font(.titleMedium)

            // 가로 배치된 피커 (곡 편집과 동일한 형태)
            VStack(spacing: Spacing.lg) {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("코드")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        Picker("코드", selection: $editedKey) {
                            ForEach(keys, id: \.self) { keyOption in
                                Text(keyOption).tag(keyOption)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .tint(.accentGold)
                        .onChange(of: editedKey) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("코드")
                        .accessibilityValue(editedKey)
                        .accessibilityHint("이 콘티에서 사용할 코드를 선택하세요")
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("템포 (BPM)")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        Picker("템포", selection: $editedTempo) {
                            ForEach(tempoOptions, id: \.self) { bpm in
                                Text("\(bpm)").tag(bpm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .tint(.accentGold)
                        .onChange(of: editedTempo) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("템포")
                        .accessibilityValue("\(editedTempo) BPM")
                        .accessibilityHint("이 콘티에서 사용할 템포를 선택하세요")
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("박자")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        Picker("박자", selection: $editedTimeSignature) {
                            ForEach(timeSignatures, id: \.self) { signature in
                                Text(signature).tag(signature)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .tint(.accentGold)
                        .onChange(of: editedTimeSignature) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("박자")
                        .accessibilityValue(editedTimeSignature)
                        .accessibilityHint("이 콘티에서 사용할 박자를 선택하세요")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.md)
                .frame(height: 120)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        editedKey = item.key ?? "C"
        editedTempo = item.tempo ?? 120
        editedTimeSignature = item.timeSignature ?? "4/4"
    }

    private func saveChanges() {
        item.key = editedKey
        item.tempo = editedTempo
        item.timeSignature = editedTimeSignature
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("콘티 메모")
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
                .tint(.accentGold)
                .onChange(of: isNotesFocused) { _, isFocused in
                    if !isFocused {
                        saveNotes()
                    }
                }
                .accessibilityLabel("콘티 메모")
                .accessibilityHint("이 곡에 대한 콘티별 메모를 입력하세요")
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

// 콘티 아이템 구조 섹션
struct SetlistItemStructureSection: View {
    @Environment(\.modelContext) private var modelContext
    let item: SetlistItem
    @Binding var isEditing: Bool

    @State private var showingAddSection = false
    @State private var editingSection: SetlistItemSection?
    @State private var deletingSection: SetlistItemSection?

    var sortedSections: [SetlistItemSection] {
        item.sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더: 제목 + 빠른 추가 버튼 (곡 편집과 동일한 형태)
            HStack(spacing: 20) {
                Text("구조")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SectionType.allCases) { type in
                            Button {
                                if type == .custom {
                                    showingAddSection = true
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        addQuickSection(type: type)
                                    }
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
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentGold.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(type.displayName) 섹션 추가")
                            .accessibilityHint("곡 구조에 \(type.displayName) 섹션을 추가합니다")
                        }
                    }
                }
            }

            if sortedSections.isEmpty {
                // 빈 상태
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("곡 구조가 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("섹션을 추가하여 곡의 구조를 만들어보세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // 섹션 플로우 (자동 줄바꿈)
                FlowLayout(spacing: Spacing.md) {
                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                        HStack(spacing: Spacing.sm) {
                            // 섹션 버튼 (박스 스타일, 색상 적용)
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editingSection = section
                                }
                            } label: {
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
                            .accessibilityLabel(section.displayLabel)
                            .accessibilityHint("섹션을 편집하려면 누르세요")

                            // 삭제 버튼 (편집 모드에서만, 섹션과 분리)
                            if isEditing {
                                Button {
                                    deletingSection = section
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(section.displayLabel) 섹션 삭제")
                            }

                            // 화살표 (마지막이 아닐 때)
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
            AddSetlistItemSectionView(item: item)
        }
        .sheet(item: $editingSection) { section in
            EditSetlistItemSectionLabelView(section: section)
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
                    deleteSection(section)
                    deletingSection = nil
                }
            }
        } message: {
            Text("이 섹션을 삭제하시겠습니까?")
        }
    }

    private func deleteSection(_ section: SetlistItemSection) {
        if let index = item.sections.firstIndex(where: { $0.id == section.id }) {
            item.sections.remove(at: index)
            modelContext.delete(section)

            // 순서 재정렬
            for (newOrder, sec) in sortedSections.enumerated() {
                sec.order = newOrder
            }

            item.setlist?.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func addQuickSection(type: SectionType) {
        let section = SetlistItemSection(
            type: type,
            order: item.sections.count,
            customLabel: nil,
            customName: nil
        )
        section.setlistItem = item
        item.sections.append(section)

        modelContext.insert(section)
        item.setlist?.updatedAt = Date()

        try? modelContext.save()
    }
}

// 콘티 아이템 섹션 추가 뷰
struct AddSetlistItemSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: SetlistItem

    @State private var customLabel: String = ""
    @State private var customName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Custom 타입일 때 이름 입력
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
        let section = SetlistItemSection(
            type: .custom,
            order: item.sections.count,
            customLabel: customLabel.isEmpty ? nil : customLabel,
            customName: customName.isEmpty ? nil : customName
        )
        section.setlistItem = item
        item.sections.append(section)

        modelContext.insert(section)
        item.setlist?.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

// 콘티 아이템 악보 섹션
struct SetlistItemSheetMusicSection: View {
    let item: SetlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("악보")
                .font(.titleMedium)

            if item.sheetMusicImages.isEmpty {
                Text("악보가 없습니다")
                    .foregroundStyle(Color.textSecondary)
                    .font(.bodyMedium)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(Array(item.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                .shadow(radius: 2)
                        }
                    }
                }
            }
        }
    }
}

// 섹션 라벨 편집 뷰
struct EditSetlistItemSectionLabelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let section: SetlistItemSection
    @State private var selectedType: SectionType = .verse
    @State private var customLabel: String = ""
    @State private var customName: String = ""
    @State private var showingDeleteAlert = false

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

                // Custom 타입일 때 이름 입력
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

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("섹션 삭제")
                        }
                    }
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
                        saveLabel()
                    }
                }
            }
            .alert("섹션 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    deleteSection()
                }
            } message: {
                Text("이 섹션을 삭제하시겠습니까?")
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

    private func saveLabel() {
        section.type = selectedType
        section.customLabel = customLabel.isEmpty ? nil : customLabel
        section.customName = customName.isEmpty ? nil : customName
        section.setlistItem?.setlist?.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }

    private func deleteSection() {
        guard let item = section.setlistItem else {
            dismiss()
            return
        }

        if let index = item.sections.firstIndex(where: { $0.id == section.id }) {
            item.sections.remove(at: index)
            modelContext.delete(section)

            // 순서 재정렬
            let sortedSections = item.sections.sorted { $0.order < $1.order }
            for (index, section) in sortedSections.enumerated() {
                section.order = index
            }

            item.setlist?.updatedAt = Date()
            try? modelContext.save()
        }

        dismiss()
    }
}

#Preview {
    let song = Song(title: "Amazing Grace", tempo: 120, key: "C", timeSignature: "4/4")
    let item = SetlistItem(order: 0, cloneFrom: song)

    return SetlistItemDetailView(item: item)
        .modelContainer(for: [Song.self, Setlist.self, SetlistItem.self, SetlistItemSection.self], inMemory: true)
}
