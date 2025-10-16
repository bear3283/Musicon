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
                    // 제목 편집
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("제목")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        TextField("콘티 제목", text: $editedTitle)
                            .font(.bodyLarge)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            .tint(.accentGold)
                            .accessibilityLabel("콘티 제목")
                            .accessibilityHint("콘티의 제목을 입력하세요")
                    }

                    // 공연 날짜
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("공연 날짜")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        DatePicker("", selection: $editedDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.accentGold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 메모 편집
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("메모")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)

                        TextField("메모를 입력하세요", text: $editedNotes, axis: .vertical)
                            .font(.bodyLarge)
                            .textFieldStyle(.plain)
                            .lineLimit(1...10)
                            .padding(Spacing.md)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            .tint(.accentGold)
                            .accessibilityLabel("메모")
                            .accessibilityHint("콘티에 대한 메모를 입력하세요")
                    }
                }
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
