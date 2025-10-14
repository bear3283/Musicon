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

    @State private var editedKey: String = ""
    @State private var editedTempo: Int = 120
    @State private var editedTimeSignature: String = "4/4"

    let keys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))
    let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                // 편집 모드: 제목만
                Text("곡 정보")
                    .font(.headline)

                // 편집 모드
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("코드")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("코드", selection: $editedKey) {
                                ForEach(keys, id: \.self) { keyOption in
                                    Text(keyOption).tag(keyOption)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("템포 (BPM)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("템포", selection: $editedTempo) {
                                ForEach(tempoOptions, id: \.self) { bpm in
                                    Text("\(bpm)").tag(bpm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("박자")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("박자", selection: $editedTimeSignature) {
                                ForEach(timeSignatures, id: \.self) { signature in
                                    Text(signature).tag(signature)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .frame(height: 140)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // 보기 모드: 한 줄로 배치
                HStack(spacing: 12) {
                    Text("곡 정보")
                        .font(.headline)

                    Spacer()

                    // 코드
                    HStack(spacing: 4) {
                        Text("코드")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(song.key ?? "-")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }

                    // 템포
                    HStack(spacing: 4) {
                        Text("템포")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(song.tempo != nil ? "\(song.tempo!)" : "-")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }

                    // 박자
                    HStack(spacing: 4) {
                        Text("박자")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(song.timeSignature ?? "-")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
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
