//
//  SetlistInfoSection.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct SetlistInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    let setlist: Setlist
    @Binding var isEditing: Bool

    @State private var editedTitle: String = ""
    @State private var editedDate: Date = Date()
    @State private var editedNotes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("콘티 정보")
                .font(.headline)

            if isEditing {
                // 편집 모드
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Text("공연 날짜")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("/")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $editedDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("콘티 제목", text: $editedTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $editedNotes)
                            .frame(height: 100)
                            .multilineTextAlignment(.leading)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // 보기 모드
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("공연 날짜")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let date = setlist.performanceDate {
                                Text(date, style: .date)
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                Text("-")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("곡 수")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(setlist.items.count)곡")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }

                    if let notes = setlist.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("메모")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            editedTitle = setlist.title
            editedDate = setlist.performanceDate ?? Date()
            editedNotes = setlist.notes ?? ""
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                saveSetlistInfo()
            }
        }
    }

    private func saveSetlistInfo() {
        setlist.title = editedTitle
        setlist.performanceDate = editedDate
        setlist.notes = editedNotes.isEmpty ? nil : editedNotes
        setlist.updatedAt = Date()

        try? modelContext.save()
    }
}

#Preview {
    SetlistInfoSection(
        setlist: Setlist(title: "Test", performanceDate: Date(), notes: "Test notes"),
        isEditing: .constant(false)
    )
    .padding()
}
