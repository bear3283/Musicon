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
    @Environment(\.dismiss) private var dismiss

    let item: SetlistItem

    @State private var customKey: String = ""
    @State private var customTempo: Int = 120
    @State private var notes: String = ""

    @State private var useCustomKey = false
    @State private var useCustomTempo = false

    let keys = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
        "Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m", "Am", "A#m", "Bm"
    ]
    let tempoOptions = Array(stride(from: 40, through: 200, by: 5))

    var song: Song {
        item.song
    }

    var body: some View {
        NavigationStack {
            Form {
                // 곡 정보
                Section("곡 정보") {
                    HStack {
                        Text("곡 제목")
                        Spacer()
                        Text(song.title)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("원곡 키")
                        Spacer()
                        Text(song.key ?? "-")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("원곡 템포")
                        Spacer()
                        Text(song.tempo != nil ? "\(song.tempo!) BPM" : "-")
                            .foregroundStyle(.secondary)
                    }
                }

                // 커스터마이징
                Section {
                    Toggle("커스텀 키 사용", isOn: $useCustomKey)

                    if useCustomKey {
                        Picker("키", selection: $customKey) {
                            ForEach(keys, id: \.self) { keyOption in
                                Text(keyOption).tag(keyOption)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                } header: {
                    Text("키 설정")
                } footer: {
                    if useCustomKey {
                        Text("이 콘티에서만 \(customKey) 키로 연주됩니다")
                    }
                }

                Section {
                    Toggle("커스텀 템포 사용", isOn: $useCustomTempo)

                    if useCustomTempo {
                        Picker("템포", selection: $customTempo) {
                            ForEach(tempoOptions, id: \.self) { bpm in
                                Text("\(bpm)").tag(bpm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                } header: {
                    Text("템포 설정")
                } footer: {
                    if useCustomTempo {
                        Text("이 콘티에서만 \(customTempo) BPM으로 연주됩니다")
                    }
                }

                // 메모
                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("곡 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveCustomization()
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    private func loadCurrentValues() {
        // 커스텀 키
        if let customKeyValue = item.customKey {
            customKey = customKeyValue
            useCustomKey = true
        } else {
            customKey = song.key ?? "C"
            useCustomKey = false
        }

        // 커스텀 템포
        if let customTempoValue = item.customTempo {
            customTempo = customTempoValue
            useCustomTempo = true
        } else {
            customTempo = song.tempo ?? 120
            useCustomTempo = false
        }

        // 메모
        notes = item.notes ?? ""
    }

    private func saveCustomization() {
        item.customKey = useCustomKey ? customKey : nil
        item.customTempo = useCustomTempo ? customTempo : nil
        item.notes = notes.isEmpty ? nil : notes

        item.setlist?.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    SetlistItemDetailView(
        item: SetlistItem(
            order: 0,
            song: Song(title: "Amazing Grace", tempo: 120, key: "C", timeSignature: "4/4")
        )
    )
    .modelContainer(for: [Song.self, Setlist.self], inMemory: true)
}
