//
//  SongStructureSection.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct SongStructureSection: View {
    @Environment(\.modelContext) private var modelContext
    let song: Song
    @Binding var isEditing: Bool

    @State private var showingAddSection = false
    @State private var editingSection: SongSection?
    @State private var deletingSection: SongSection?

    var sortedSections: [SongSection] {
        (song.sections ?? []).sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더: 제목 + 빠른 추가 버튼
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
            } else if isEditing {
                // 편집 모드: List로 드래그앤드랍 가능
                VStack(alignment: .leading, spacing: 8) {
                    // 편집 모드 안내
                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("길게 눌러서 순서를 변경하세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

                    List {
                        ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                            HStack(spacing: Spacing.sm) {
                                // 섹션 버튼 (박스 스타일, 색상 적용)
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        editingSection = section
                                    }
                                } label: {
                                    let sectionColor = (section.type ?? .verse).color
                                    Text(section.displayLabel)
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(sectionColor)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(sectionColor.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(section.displayLabel)
                                .accessibilityHint("섹션을 편집하려면 누르세요")

                                Spacer()

                                // 삭제 버튼
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
                        }
                        .onMove(perform: moveSection)
                    }
                    .listStyle(.plain)
                    .frame(height: min(CGFloat(sortedSections.count * 52), 400))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 일반 모드: 섹션 플로우 (자동 줄바꿈)
                FlowLayout(spacing: Spacing.md) {
                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                        HStack(spacing: Spacing.sm) {
                            // 섹션 버튼 (박스 스타일, 색상 적용)
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editingSection = section
                                }
                            } label: {
                                let sectionColor = (section.type ?? .verse).color
                                Text(section.displayLabel)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(sectionColor)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(sectionColor.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(section.displayLabel)
                            .accessibilityHint("섹션을 편집하려면 누르세요")

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
            AddSectionView(song: song, initialType: .custom)
        }
        .sheet(item: $editingSection) { section in
            EditSectionLabelView(section: section)
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

    private func moveSection(from: IndexSet, to: Int) {
        var sections = sortedSections
        sections.move(fromOffsets: from, toOffset: to)

        // 순서 재정렬
        for (index, section) in sections.enumerated() {
            section.order = index
        }

        song.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteSection(_ section: SongSection) {
        if let index = song.sections?.firstIndex(where: { $0.id == section.id }) {
            song.sections?.remove(at: index)
            modelContext.delete(section)

            // 순서 재정렬
            for (index, section) in sortedSections.enumerated() {
                section.order = index
            }

            song.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func addQuickSection(type: SectionType) {
        // 옵셔널 배열 초기화
        if song.sections == nil {
            song.sections = []
        }

        let section = SongSection(
            type: type,
            order: song.sections?.count ?? 0,
            customLabel: nil
        )
        section.song = song
        song.sections?.append(section)

        modelContext.insert(section)
        song.updatedAt = Date()

        try? modelContext.save()
    }
}

struct EditSectionLabelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let section: SongSection
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
                selectedType = section.type ?? .verse // 옵셔널 처리
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
        section.song?.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }

    private func deleteSection() {
        guard let song = section.song else {
            dismiss()
            return
        }

        if let index = song.sections?.firstIndex(where: { $0.id == section.id }) {
            song.sections?.remove(at: index)
            modelContext.delete(section)

            // 순서 재정렬
            let sortedSections = (song.sections ?? []).sorted { $0.order < $1.order }
            for (index, section) in sortedSections.enumerated() {
                section.order = index
            }

            song.updatedAt = Date()
            try? modelContext.save()
        }

        dismiss()
    }
}

#Preview {
    SongStructureSection(song: Song(title: "Test"), isEditing: .constant(false))
        .padding()
        .modelContainer(for: Song.self, inMemory: true)
}
