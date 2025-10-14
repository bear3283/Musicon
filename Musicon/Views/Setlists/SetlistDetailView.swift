//
//  SetlistDetailView.swift
//  Musicon
//
//  Created by bear on 10/13/25.
//

import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let setlist: Setlist

    @State private var isEditing = false
    @State private var showingAddSong = false
    @State private var currentSongIndex = 0
    @State private var showPageIndicator = true
    @State private var hideTask: Task<Void, Never>?

    var sortedItems: [SetlistItem] {
        setlist.items.sorted { $0.order < $1.order }
    }

    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("곡이 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("곡을 추가하여 콘티를 구성하세요")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    var addSongButton: some View {
        Button {
            showingAddSong = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("곡 추가")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    var body: some View {
        Group {
            if isEditing {
                // 편집 모드: 전체 스크롤 가능한 리스트
                List {
                    // 콘티 정보 섹션
                    Section {
                        SetlistInfoSection(setlist: setlist, isEditing: $isEditing)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: horizontalSizeClass == .regular ? 32 : 16, bottom: 0, trailing: horizontalSizeClass == .regular ? 32 : 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // 구분선
                    Section {
                        Divider()
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: horizontalSizeClass == .regular ? 32 : 16, bottom: 12, trailing: horizontalSizeClass == .regular ? 32 : 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // 곡 목록 헤더
                    Section {
                        Text("곡 목록")
                            .font(.headline)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: horizontalSizeClass == .regular ? 32 : 16, bottom: 12, trailing: horizontalSizeClass == .regular ? 32 : 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // 곡 목록 (드래그 가능)
                    if sortedItems.isEmpty {
                        Section {
                            emptyStateView
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        Section {
                            ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                                SetlistSongSimpleCard(
                                    index: index + 1,
                                    item: item,
                                    onDelete: {
                                        deleteItem(item)
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: horizontalSizeClass == .regular ? 32 : 16, bottom: 6, trailing: horizontalSizeClass == .regular ? 32 : 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onMove { from, to in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    moveItem(from: from, to: to)
                                }
                            }
                        }
                    }

                    // 곡 추가 버튼
                    Section {
                        addSongButton
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: horizontalSizeClass == .regular ? 32 : 16, bottom: 6, trailing: horizontalSizeClass == .regular ? 32 : 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            } else {
                // 일반 모드: 전체 스크롤 + 페이지 넘기기
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 콘티 정보
                        SetlistInfoSection(setlist: setlist, isEditing: $isEditing)

                        Divider()

                        Text("곡 목록")
                            .font(.headline)

                        // 곡 카드 (페이지 형식)
                        if sortedItems.isEmpty {
                            emptyStateView
                            addSongButton
                        } else {
                            GeometryReader { geometry in
                                ZStack {
                                    TabView(selection: $currentSongIndex) {
                                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                                            VStack {
                                                SetlistSongDetailCard(
                                                    index: index + 1,
                                                    item: item,
                                                    isEditing: isEditing,
                                                    onDelete: {
                                                        deleteItem(item)
                                                    },
                                                    isIPad: horizontalSizeClass == .regular
                                                )
                                                Spacer(minLength: 0)
                                            }
                                            .tag(index)
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .never))
                                    .onChange(of: currentSongIndex) { _, _ in
                                        showIndicatorTemporarily()
                                    }
                                    .onAppear {
                                        showIndicatorTemporarily()
                                    }

                                    // 커스텀 페이지 인디케이터
                                    if showPageIndicator && sortedItems.count > 1 {
                                        VStack {
                                            Spacer()
                                            HStack(spacing: 8) {
                                                ForEach(0..<sortedItems.count, id: \.self) { index in
                                                    Circle()
                                                        .fill(index == currentSongIndex ? Color.white : Color.white.opacity(0.5))
                                                        .frame(width: 8, height: 8)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Capsule())
                                            .padding(.bottom, 20)
                                        }
                                        .transition(.opacity)
                                    }
                                }
                            }
                            .frame(height: horizontalSizeClass == .regular ? 1000 : 700)
                        }
                    }
                    .padding(horizontalSizeClass == .regular ? 32 : 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle(setlist.title)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "완료" : "편집") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditing.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSong) {
            AddSongToSetlistView(setlist: setlist)
        }
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }

    private func moveItem(from: IndexSet, to: Int) {
        var items = sortedItems
        items.move(fromOffsets: from, toOffset: to)

        // 순서 재정렬
        for (index, item) in items.enumerated() {
            item.order = index
        }

        setlist.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteItem(_ item: SetlistItem) {
        if let index = setlist.items.firstIndex(where: { $0.id == item.id }) {
            setlist.items.remove(at: index)
            modelContext.delete(item)

            // 순서 재정렬
            for (index, item) in sortedItems.enumerated() {
                item.order = index
            }

            setlist.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func showIndicatorTemporarily() {
        // 기존 타이머 취소
        hideTask?.cancel()

        // 인디케이터 표시
        withAnimation {
            showPageIndicator = true
        }

        // 2초 후 숨기기
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                withAnimation {
                    showPageIndicator = false
                }
            }
        }
    }
}

// 곡 간단 카드 (편집 모드용 - 번호, 제목, 기본 정보만)
struct SetlistSongSimpleCard: View {
    let index: Int
    let item: SetlistItem
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var song: Song {
        item.song
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 번호
            Text("\(index)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .frame(width: 40)

            // 곡 정보
            VStack(alignment: .leading, spacing: 8) {
                // 제목
                Text(song.title)
                    .font(.headline)

                // 코드, 템포, 박자
                HStack(spacing: 8) {
                    if let key = item.displayKey {
                        HStack(spacing: 2) {
                            Text(key)
                                .font(.caption)
                            if item.customKey != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.customKey != nil ? .blue.opacity(0.4) : .blue.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    if let tempo = item.displayTempo {
                        HStack(spacing: 2) {
                            Text("\(tempo) BPM")
                                .font(.caption)
                            if item.customTempo != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.customTempo != nil ? .green.opacity(0.4) : .green.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    if let timeSignature = song.timeSignature {
                        Text(timeSignature)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // 삭제 버튼
            Button {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("곡 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 곡을 콘티에서 삭제하시겠습니까?")
        }
    }
}

// 곡 상세 카드 (번호, 곡정보, 구조, 악보 포함)
struct SetlistSongDetailCard: View {
    @Environment(\.modelContext) private var modelContext
    let index: Int
    let item: SetlistItem
    let isEditing: Bool
    let onDelete: () -> Void
    var isIPad: Bool = false

    @State private var showingItemDetail = false
    @State private var showingDeleteAlert = false

    var song: Song {
        item.song
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더: 번호, 제목, 삭제 버튼
            HStack(alignment: .center, spacing: 12) {
                // 번호
                Text("\(index)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                // 곡 제목
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                }

                Spacer()

                // 설정 버튼
                Button {
                    showingItemDetail = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                // 삭제 버튼 (편집 모드에서만)
                if isEditing {
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 곡 정보
            HStack(spacing: 8) {
                if let key = item.displayKey {
                    HStack(spacing: 2) {
                        Text(key)
                            .font(.caption)
                        if item.customKey != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.customKey != nil ? .blue.opacity(0.4) : .blue.opacity(0.2))
                    .clipShape(Capsule())
                }

                if let tempo = item.displayTempo {
                    HStack(spacing: 2) {
                        Text("\(tempo) BPM")
                            .font(.caption)
                        if item.customTempo != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.customTempo != nil ? .green.opacity(0.4) : .green.opacity(0.2))
                    .clipShape(Capsule())
                }

                if let timeSignature = song.timeSignature {
                    Text(timeSignature)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
                        .clipShape(Capsule())
                }

                if item.notes != nil {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 곡 구조
            if !song.sections.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("구조")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    let sortedSections = song.sections.sorted(by: { $0.order < $1.order })

                    FlowLayout(spacing: 6) {
                        ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                            HStack(spacing: 3) {
                                Text(section.displayLabel)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                if index < sortedSections.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // 악보 이미지
            if !song.sheetMusicImages.isEmpty {
                let sheetMusicHeight: CGFloat = isIPad ? 600 : 400

                VStack(alignment: .leading, spacing: 8) {
                    Text("악보")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    GeometryReader { geometry in
                        let imageWidth: CGFloat = geometry.size.width * (isIPad ? 0.85 : 0.80)
                        let spacing: CGFloat = 16

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: spacing) {
                                ForEach(Array(song.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                                    if let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: imageWidth)
                                            .frame(maxHeight: sheetMusicHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .scrollTransition { content, phase in
                                                content
                                                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
                                            }
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, (geometry.size.width - imageWidth) / 2)
                        }
                        .scrollTargetBehavior(.viewAligned)
                    }
                    .frame(height: sheetMusicHeight)
                }
            }

            // 메모
            if let notes = item.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("메모")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingItemDetail) {
            SetlistItemDetailView(item: item)
        }
        .alert("곡 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 곡을 콘티에서 삭제하시겠습니까?")
        }
    }
}

#Preview {
    NavigationStack {
        SetlistDetailView(setlist: Setlist(
            title: "주일 예배",
            performanceDate: Date(),
            notes: "테스트 메모"
        ))
    }
    .modelContainer(for: Setlist.self, inMemory: true)
}
