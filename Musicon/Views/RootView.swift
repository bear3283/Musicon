//
//  RootView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

enum SidebarTab: Hashable {
    case songs
    case setlists
}

struct RootView: View {
    @State private var selectedTab: SidebarTab? = nil
    @State private var navigationPath = NavigationPath()

    var body: some View {
        if DeviceType.isIPad {
            // iPad: Split View
            iPadLayout()
        } else {
            // iPhone: Custom Tab View
            iPhoneLayout()
        }
    }

    @ViewBuilder
    private func iPhoneLayout() -> some View {
        TabView {
            SongListView()
                .tabItem {
                    Label("곡", systemImage: "music.note")
                }

            SetlistListView()
                .tabItem {
                    Label("콘티", systemImage: "music.note.list")
                }
        }
        .tint(.accentGold)
    }

    @ViewBuilder
    private func iPadLayout() -> some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            NavigationStack(path: $navigationPath) {
                if let selectedTab = selectedTab {
                    switch selectedTab {
                    case .songs:
                        SongListContentView()
                    case .setlists:
                        SetlistListContentView()
                    }
                } else {
                    ContentPlaceholderView()
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // 사이드바 탭 변경 시 네비게이션 스택 초기화
                navigationPath = NavigationPath()
            }
        }
    }
}

// MARK: - iPad Sidebar
struct SidebarView: View {
    @Binding var selectedTab: SidebarTab?

    var body: some View {
        List {
            Section {
                Button {
                    selectedTab = .songs
                } label: {
                    HStack {
                        Label("곡", systemImage: "music.note")
                            .font(.bodyLarge)
                            .foregroundStyle(selectedTab == .songs ? Color.accentGold : Color.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == .songs ? Color.accentGold.opacity(0.2) : Color.clear)

                Button {
                    selectedTab = .setlists
                } label: {
                    HStack {
                        Label("콘티", systemImage: "music.note.list")
                            .font(.bodyLarge)
                            .foregroundStyle(selectedTab == .setlists ? Color.accentGold : Color.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == .setlists ? Color.accentGold.opacity(0.2) : Color.clear)
            } header: {
                Text("라이브러리")
                    .font(.labelLarge)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .navigationTitle("Musicon")
        .tint(.accentGold)
    }
}

// MARK: - Content Views
struct SongListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var searchText = ""
    @State private var showingCreateSheet = false

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.title.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        Group {
            if filteredSongs.isEmpty {
                ContentUnavailableView {
                    Label("곡이 없습니다", systemImage: "music.note")
                } description: {
                    Text("+ 버튼을 눌러 첫 곡을 추가해보세요")
                }
            } else {
                List {
                    ForEach(filteredSongs) { song in
                        NavigationLink(value: song) {
                            SongRowView(song: song)
                        }
                    }
                    .onDelete(perform: deleteSongs)
                }
            }
        }
        .navigationTitle("곡 목록")
        .searchable(text: $searchText, prompt: "곡 검색")
        .navigationDestination(for: Song.self) { song in
            SongDetailView(song: song)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(Color.accentGold)
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateSongView()
        }
    }

    private func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            let song = filteredSongs[index]
            modelContext.delete(song)
        }
    }
}

struct SetlistListContentView: View {
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
                        .font(.title3)
                        .foregroundStyle(Color.accentGold)
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateSetlistView()
        }
    }

    private func deleteSetlists(at offsets: IndexSet) {
        for index in offsets {
            let setlist = filteredSetlists[index]
            modelContext.delete(setlist)
        }
    }
}

// MARK: - Placeholder Views
struct ContentPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.accentGold.opacity(0.6))

            Text("시작하기")
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)

            Text("왼쪽 사이드바에서\n곡 또는 콘티를 선택하세요")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Song.self, Setlist.self], inMemory: true)
}
