//
//  SongInfoSection.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct SongInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    let song: Song
    @Binding var isEditing: Bool

    @State private var editedTitle: String = ""
    @State private var editedKey: String = ""
    @State private var editedTempo: Int = 120
    @State private var editedTimeSignature: String = "4/4"

    let keys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isEditing {
                // 편집 모드: 제목 편집 가능
                Text("곡 정보")
                    .font(.titleMedium)

                // 제목 편집
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("제목")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)

                    TextField("곡 제목", text: $editedTitle)
                        .font(.bodyLarge)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .tint(.accentGold)
                        .accessibilityLabel("곡 제목")
                        .accessibilityHint("곡의 제목을 입력하세요")
                }

                // 편집 모드
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
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.md)
                    .frame(height: 140)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
            } else {
                // 보기 모드: 한 줄로 배치
                HStack(spacing: Spacing.md) {
                    Text("곡 정보")
                        .font(.titleMedium)

                    Spacer()

                    // 코드
                    if let key = song.key {
                        Badge(key, style: .code)
                    }

                    // 템포
                    if let tempo = song.tempo {
                        Badge("\(tempo) BPM", style: .tempo)
                    }

                    // 박자
                    if let timeSignature = song.timeSignature {
                        Badge(timeSignature, style: .signature)
                    }
                }
            }
        }
        .onAppear {
            editedTitle = song.title
            editedKey = song.key ?? "C"
            editedTempo = song.tempo ?? 120
            editedTimeSignature = song.timeSignature ?? "4/4"
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                // 편집 완료 시 저장
                saveSongInfo()
            }
        }
    }

    private func saveSongInfo() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            song.title = trimmedTitle
        }
        song.key = editedKey
        song.tempo = editedTempo
        song.timeSignature = editedTimeSignature
        song.updatedAt = Date()

        try? modelContext.save()
    }
}

#Preview {
    SongInfoSection(
        song: Song(title: "Test", tempo: 120, key: "C", timeSignature: "4/4"),
        isEditing: .constant(false)
    )
    .padding()
}
