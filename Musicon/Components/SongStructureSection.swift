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
        song.sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더: 제목 + 빠른 추가 버튼
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
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

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
        .sheet(isPresented: $showingAddSection) {
            AddSectionView(song: song)
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
        if let index = song.sections.firstIndex(where: { $0.id == section.id }) {
            song.sections.remove(at: index)
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
        let section = SongSection(
            type: type,
            order: song.sections.count,
            customLabel: nil
        )
        section.song = song
        song.sections.append(section)

        modelContext.insert(section)
        song.updatedAt = Date()

        try? modelContext.save()
    }
}

struct EditSectionLabelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let section: SongSection
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
        section.song?.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }

    private func deleteSection() {
        guard let song = section.song else {
            dismiss()
            return
        }

        if let index = song.sections.firstIndex(where: { $0.id == section.id }) {
            song.sections.remove(at: index)
            modelContext.delete(section)

            // 순서 재정렬
            let sortedSections = song.sections.sorted { $0.order < $1.order }
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
