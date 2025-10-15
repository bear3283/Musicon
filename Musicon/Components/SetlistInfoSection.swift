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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("콘티 정보")
                .font(.titleMedium)

            if isEditing {
                // 편집 모드
                VStack(spacing: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Text("공연 날짜")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        Text("/")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        DatePicker("", selection: $editedDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.accentGold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("제목")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)
                        TextField("콘티 제목", text: $editedTitle)
                            .textFieldStyle(.roundedBorder)
                            .tint(.accentGold)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("메모")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)
                        TextEditor(text: $editedNotes)
                            .frame(height: 100)
                            .multilineTextAlignment(.leading)
                            .padding(Spacing.sm)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            .tint(.accentGold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            } else {
                // 보기 모드
                VStack(spacing: Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("공연 날짜")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            if let date = setlist.performanceDate {
                                Text(date, style: .date)
                                    .font(.bodyLarge)
                                    .fontWeight(.medium)
                            } else {
                                Text("-")
                                    .font(.bodyLarge)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("곡 수")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            HStack(spacing: 4) {
                                Image(systemName: "music.note.list")
                                    .font(.labelSmall)
                                Text("\(setlist.items.count)곡")
                                    .font(.bodyLarge)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Color.accentGold)
                        }
                    }

                    if let notes = setlist.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("메모")
                                .font(.labelMedium)
                                .foregroundStyle(Color.textSecondary)
                            Text(notes)
                                .font(.bodyLarge)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
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
