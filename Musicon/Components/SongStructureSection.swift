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

    @State private var showingAddSection = false
    @State private var editingSection: SongSection?

    var sortedSections: [SongSection] {
        song.sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("곡 구조")
                .font(.headline)

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
                // 섹션 목록
                VStack(spacing: 8) {
                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .leading)

                            Button {
                                editingSection = section
                            } label: {
                                HStack {
                                    Text(section.displayLabel)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                deleteSection(section)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .onMove { from, to in
                        moveSection(from: from, to: to)
                    }
                }
            }

            // 빠른 섹션 추가 버튼들
            VStack(spacing: 12) {
                Text("빠른 추가")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(SectionType.allCases.filter { $0 != .custom }) { type in
                        Button {
                            addQuickSection(type: type)
                        } label: {
                            VStack(spacing: 4) {
                                Text(type.rawValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(type.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionView(song: song)
        }
        .sheet(item: $editingSection) { section in
            EditSectionLabelView(section: section)
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
}

#Preview {
    SongStructureSection(song: Song(title: "Test"))
        .padding()
        .modelContainer(for: Song.self, inMemory: true)
}
