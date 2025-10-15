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

            // 기본 정보 표시
            VStack(spacing: Spacing.md) {
                // 코드 설정
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("코드")
                            .font(.labelLarge)
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        Picker("코드", selection: $editedKey) {
                            ForEach(keys, id: \.self) { keyOption in
                                Text(keyOption).tag(keyOption)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                        .tint(.accentGold)
                        .onChange(of: editedKey) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("코드")
                        .accessibilityValue(editedKey)
                        .accessibilityHint("이 콘티에서 사용할 코드를 선택하세요")
                    }
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }

                // 템포 설정
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("템포")
                            .font(.labelLarge)
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        Picker("템포", selection: $editedTempo) {
                            ForEach(tempoOptions, id: \.self) { bpm in
                                Text("\(bpm)").tag(bpm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                        .tint(.accentGold)
                        .onChange(of: editedTempo) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("템포")
                        .accessibilityValue("\(editedTempo) BPM")
                        .accessibilityHint("이 콘티에서 사용할 템포를 선택하세요")
                    }
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }

                // 박자 설정
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("박자")
                            .font(.labelLarge)
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        Picker("박자", selection: $editedTimeSignature) {
                            ForEach(timeSignatures, id: \.self) { signature in
                                Text(signature).tag(signature)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                        .tint(.accentGold)
                        .onChange(of: editedTimeSignature) { _, _ in
                            saveChanges()
                        }
                        .accessibilityLabel("박자")
                        .accessibilityValue(editedTimeSignature)
                        .accessibilityHint("이 콘티에서 사용할 박자를 선택하세요")
                    }
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
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

    var sortedSections: [SetlistItemSection] {
        item.sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("곡 구조")
                    .font(.titleMedium)

                Spacer()

                if isEditing {
                    Button {
                        showingAddSection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentGold)
                    }
                }
            }

            if sortedSections.isEmpty {
                Text("구조가 없습니다")
                    .foregroundStyle(Color.textSecondary)
                    .font(.bodyMedium)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(sortedSections) { section in
                        HStack(spacing: 3) {
                            Text(section.displayLabel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )

                            if isEditing {
                                Button {
                                    deleteSection(section)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSetlistItemSectionView(item: item)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(Array(item.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
            }
        }
    }
}

// 섹션 추가 뷰
struct AddSetlistItemSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: SetlistItem

    @State private var selectedType: SectionType = .intro
    @State private var customLabel = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("섹션 타입") {
                    Picker("타입", selection: $selectedType) {
                        ForEach(SectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("커스텀 라벨 (선택사항)") {
                    TextField("예: 1, 2, A, B", text: $customLabel)
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
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addSection() {
        let newSection = SetlistItemSection(
            type: selectedType,
            order: item.sections.count,
            customLabel: customLabel.isEmpty ? nil : customLabel
        )
        newSection.setlistItem = item

        item.sections.append(newSection)
        modelContext.insert(newSection)

        item.setlist?.updatedAt = Date()
        try? modelContext.save()

        dismiss()
    }
}

#Preview {
    let song = Song(title: "Amazing Grace", tempo: 120, key: "C", timeSignature: "4/4")
    let item = SetlistItem(order: 0, cloneFrom: song)

    return SetlistItemDetailView(item: item)
        .modelContainer(for: [Song.self, Setlist.self, SetlistItem.self, SetlistItemSection.self], inMemory: true)
}
