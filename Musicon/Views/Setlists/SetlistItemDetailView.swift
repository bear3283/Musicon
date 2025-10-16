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
                    SetlistItemStructureSection(item: item, isEditing: $isEditing)

                    Divider()

                    // 악보 섹션
                    SetlistItemSheetMusicSection(item: item)

                    Divider()

                    // 콘티 메모 섹션
                    SetlistItemNotesSection(item: item)
                }
                .padding(horizontalSizeClass == .regular ? 32 : 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .tint(.accentGold)
        }
    }
}

// 순서 정보 섹션
struct SetlistItemOrderSection: View {
    let order: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("순서")
                .font(.titleMedium)

            HStack {
                Text("\(order) / \(total)")
                    .font(.displayMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentGold)
            }
        }
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
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
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
                .frame(height: 140)
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
                        ForEach(SectionType.allCases.filter { $0 != .custom }) { type in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    addQuickSection(type: type)
                                }
                            } label: {
                                Text(type.rawValue)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
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
                FlowLayout(spacing: 6) {
                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                        HStack(spacing: 3) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editingSection = section
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(section.displayLabel)
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    if isEditing {
                                        Button {
                                            deletingSection = section
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                        }
                                        .accessibilityLabel("\(section.displayLabel) 섹션 삭제")
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(section.displayLabel)
                            .accessibilityHint("섹션을 편집하려면 누르세요")

                            if index < sortedSections.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
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
            customLabel: nil
        )
        section.setlistItem = item
        item.sections.append(section)

        modelContext.insert(section)
        item.setlist?.updatedAt = Date()

        try? modelContext.save()
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
    @State private var customLabel: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("섹션 타입") {
                    HStack {
                        Text(section.type.displayName)
                            .font(.headline)
                        Spacer()
                        Text("(\(section.type.rawValue))")
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.blue)
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
                customLabel = section.customLabel ?? ""
            }
        }
    }

    private var previewLabel: String {
        if customLabel.isEmpty {
            return section.type.rawValue
        } else {
            return "\(section.type.rawValue)\(customLabel)"
        }
    }

    private func saveLabel() {
        section.customLabel = customLabel.isEmpty ? nil : customLabel
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
