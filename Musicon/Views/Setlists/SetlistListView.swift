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
    @State private var showingFilterSheet = false
    @State private var setlistToDelete: Setlist?

    // 필터 상태
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var minSongCount: Int?
    @State private var maxSongCount: Int?

    var filteredSetlists: [Setlist] {
        var result = setlists

        // 검색어 필터링 (제목, 날짜, 메모)
        if !searchText.isEmpty {
            result = result.filter { setlist in
                setlist.title.localizedStandardContains(searchText) ||
                (setlist.notes?.localizedStandardContains(searchText) ?? false) ||
                (setlist.performanceDate != nil && formatDate(setlist.performanceDate!).localizedStandardContains(searchText))
            }
        }

        // 날짜 필터
        if let startDate = startDate {
            result = result.filter { setlist in
                guard let performanceDate = setlist.performanceDate else { return false }
                return performanceDate >= startDate
            }
        }

        if let endDate = endDate {
            result = result.filter { setlist in
                guard let performanceDate = setlist.performanceDate else { return false }
                return performanceDate <= endDate
            }
        }

        // 곡 수 필터
        if let minSongCount = minSongCount {
            result = result.filter { $0.items.count >= minSongCount }
        }

        if let maxSongCount = maxSongCount {
            result = result.filter { $0.items.count <= maxSongCount }
        }

        return result
    }

    var hasActiveFilters: Bool {
        startDate != nil || endDate != nil || minSongCount != nil || maxSongCount != nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
            .tint(Color.accentGold)
            .navigationDestination(for: Setlist.self) { setlist in
                SetlistDetailView(setlist: setlist)
            }
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? Color.accentGold : Color.textPrimary)
                    }
                    .accessibilityLabel("필터")
                    .accessibilityHint(hasActiveFilters ? "활성화된 필터가 있습니다. 필터를 변경하거나 제거할 수 있습니다" : "콘티 목록을 필터링합니다")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentGold)
                    }
                    .accessibilityLabel("새 콘티 추가")
                    .accessibilityHint("새로운 콘티를 추가합니다")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSetlistView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                SetlistFilterView(
                    startDate: $startDate,
                    endDate: $endDate,
                    minSongCount: $minSongCount,
                    maxSongCount: $maxSongCount,
                    onReset: {
                        startDate = nil
                        endDate = nil
                        minSongCount = nil
                        maxSongCount = nil
                    }
                )
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

    var accessibilityDescription: String {
        var description = setlist.title
        description += ", \(setlist.items.count)곡"

        if let date = setlist.performanceDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += ", 공연 날짜 \(formatter.string(from: date))"
        }

        return description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(setlist.title)
                .font(.titleSmall)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .font(.labelSmall)
                    Text("\(setlist.items.count)곡")
                        .font(.labelMedium)
                }
                .foregroundStyle(Color.accentGold)

                Spacer()

                if let date = setlist.performanceDate {
                    Text(date, style: .date)
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("콘티 상세 정보를 확인합니다")
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
                        .accessibilityLabel("콘티 제목")
                        .accessibilityHint("콘티의 이름을 입력하세요")

                    DatePicker(
                        "공연 날짜",
                        selection: $performanceDate,
                        displayedComponents: [.date]
                    )
                    .accessibilityLabel("공연 날짜")
                    .accessibilityHint("공연 날짜를 선택하세요")
                }

                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .accessibilityLabel("메모")
                        .accessibilityHint("콘티에 대한 메모를 입력하세요")
                }
            }
            .navigationTitle("새 콘티 추가")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.accentGold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSetlist()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.textTertiary : Color.accentGold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityHint(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "콘티 제목을 먼저 입력하세요" : "새 콘티를 추가합니다")
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

struct SetlistFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var minSongCount: Int?
    @Binding var maxSongCount: Int?

    let onReset: () -> Void

    @State private var useStartDate = false
    @State private var useEndDate = false
    @State private var localStartDate = Date()
    @State private var localEndDate = Date()
    @State private var minSongCountText = ""
    @State private var maxSongCountText = ""

    var body: some View {
        NavigationStack {
            Form {
                // 날짜 필터
                Section {
                    Toggle("시작 날짜", isOn: $useStartDate)
                        .onChange(of: useStartDate) { _, newValue in
                            if newValue {
                                startDate = localStartDate
                            } else {
                                startDate = nil
                            }
                        }

                    if useStartDate {
                        DatePicker(
                            "시작 날짜",
                            selection: $localStartDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .onChange(of: localStartDate) { _, newValue in
                            startDate = newValue
                        }
                    }

                    Toggle("종료 날짜", isOn: $useEndDate)
                        .onChange(of: useEndDate) { _, newValue in
                            if newValue {
                                endDate = localEndDate
                            } else {
                                endDate = nil
                            }
                        }

                    if useEndDate {
                        DatePicker(
                            "종료 날짜",
                            selection: $localEndDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .onChange(of: localEndDate) { _, newValue in
                            endDate = newValue
                        }
                    }
                } header: {
                    Text("공연 날짜")
                }

                // 곡 수 필터
                Section {
                    HStack {
                        Text("최소")
                        TextField("곡 수", text: $minSongCountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: minSongCountText) { _, newValue in
                                minSongCount = Int(newValue)
                            }
                    }

                    HStack {
                        Text("최대")
                        TextField("곡 수", text: $maxSongCountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: maxSongCountText) { _, newValue in
                                maxSongCount = Int(newValue)
                            }
                    }
                } header: {
                    Text("곡 수")
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.accentGold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("초기화") {
                        onReset()
                        useStartDate = false
                        useEndDate = false
                        minSongCountText = ""
                        maxSongCountText = ""
                    }
                    .foregroundStyle(Color.textSecondary)
                    .disabled(startDate == nil && endDate == nil && minSongCount == nil && maxSongCount == nil)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentGold)
                }
            }
            .onAppear {
                if let startDate = startDate {
                    useStartDate = true
                    localStartDate = startDate
                }
                if let endDate = endDate {
                    useEndDate = true
                    localEndDate = endDate
                }
                if let minSongCount = minSongCount {
                    minSongCountText = "\(minSongCount)"
                }
                if let maxSongCount = maxSongCount {
                    maxSongCountText = "\(maxSongCount)"
                }
            }
        }
    }
}

#Preview {
    SetlistListView()
        .modelContainer(for: Setlist.self, inMemory: true)
}
