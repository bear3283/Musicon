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
    var initialType: SectionType = .verse

    @State private var selectedType: SectionType = .verse
    @State private var customLabel: String = ""
    @State private var customName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Custom이 아닐 때만 섹션 타입 선택 표시
                if initialType != .custom {
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
            .onAppear {
                selectedType = initialType
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

    private func addSection() {
        // 옵셔널 배열 초기화
        if song.sections == nil {
            song.sections = []
        }

        let section = SongSection(
            type: selectedType,
            order: song.sections?.count ?? 0,
            customLabel: customLabel.isEmpty ? nil : customLabel,
            customName: customName.isEmpty ? nil : customName
        )
        section.song = song
        song.sections?.append(section)

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
