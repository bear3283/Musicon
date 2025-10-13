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
                        }
                        .onDelete(perform: deleteSetlists)
                    }
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
        }
    }

    private func deleteSetlists(at offsets: IndexSet) {
        for index in offsets {
            let setlist = filteredSetlists[index]
            modelContext.delete(setlist)
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
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addSetlist() {
        let setlist = Setlist(
            title: title,
            performanceDate: performanceDate,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(setlist)
        dismiss()
    }
}

#Preview {
    SetlistListView()
        .modelContainer(for: Setlist.self, inMemory: true)
}
