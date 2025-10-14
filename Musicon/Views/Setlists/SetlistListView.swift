//
//  SetlistListView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct SetlistListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Setlist.createdAt, order: .reverse) private var setlists: [Setlist]
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var setlistToDelete: Setlist?

    var filteredSetlists: [Setlist] {
        if searchText.isEmpty {
            return setlists
        } else {
            return setlists.filter { $0.title.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSetlists.isEmpty {
                    ContentUnavailableView {
                        Label("콘티가 없습니다", systemImage: "music.note.list")
                    } description: {
                        Text("+ 버튼을 눌러 첫 콘티를 만들어보세요")
                    }
                } else {
                    List {
                        ForEach(filteredSetlists) { setlist in
                            NavigationLink(value: setlist) {
                                SetlistRowView(setlist: setlist)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    setlistToDelete = setlist
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: filteredSetlists.count)
                }
            }
            .navigationTitle("콘티 목록")
            .searchable(text: $searchText, prompt: "콘티 검색")
            .navigationDestination(for: Setlist.self) { setlist in
                SetlistDetailView(setlist: setlist)
            }
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSetlistView()
            }
            .alert("콘티 삭제", isPresented: Binding(
                get: { setlistToDelete != nil },
                set: { if !$0 { setlistToDelete = nil } }
            )) {
                Button("취소", role: .cancel) {
                    setlistToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let setlist = setlistToDelete {
                        modelContext.delete(setlist)
                        setlistToDelete = nil
                    }
                }
            } message: {
                if let setlist = setlistToDelete {
                    Text("'\(setlist.title)'을(를) 삭제하시겠습니까?\n포함된 \(setlist.items.count)곡의 정보도 함께 삭제됩니다.")
                }
            }
        }
    }
}

struct SetlistRowView: View {
    let setlist: Setlist

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(setlist.title)
                .font(.headline)

            HStack {
                Image(systemName: "music.note.list")
                    .font(.caption)
                Text("\(setlist.items.count)곡")
                    .font(.caption)

                Spacer()

                if let date = setlist.performanceDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateSetlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var performanceDate = Date()
    @State private var notes = ""

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("콘티 제목", text: $title)

                    DatePicker(
                        "공연 날짜",
                        selection: $performanceDate,
                        displayedComponents: [.date]
                    )
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("새 콘티 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSetlist()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("유효성 검사 오류", isPresented: $showingValidationError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    private func addSetlist() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationErrorMessage = "제목을 입력해주세요"
            showingValidationError = true
            return
        }

        let setlist = Setlist(
            title: trimmedTitle,
            performanceDate: performanceDate,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )

        modelContext.insert(setlist)
        dismiss()
    }
}

#Preview {
    SetlistListView()
        .modelContainer(for: Setlist.self, inMemory: true)
}
