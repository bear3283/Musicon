//
//  AddSectionView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct AddSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song

    @State private var selectedType: SectionType = .verse
    @State private var customLabel: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("섹션 타입") {
                    Picker("타입", selection: $selectedType) {
                        ForEach(SectionType.allCases) { type in
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                Text("(\(type.rawValue))")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
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
        if customLabel.isEmpty {
            return selectedType.rawValue
        } else {
            return "\(selectedType.rawValue)\(customLabel)"
        }
    }

    private func addSection() {
        let section = SongSection(
            type: selectedType,
            order: song.sections.count,
            customLabel: customLabel.isEmpty ? nil : customLabel
        )
        section.song = song
        song.sections.append(section)

        modelContext.insert(section)
        song.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddSectionView(song: Song(title: "Test"))
        .modelContainer(for: Song.self, inMemory: true)
}
