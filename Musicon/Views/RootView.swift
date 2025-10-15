//
//  RootView.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Split View
            iPadLayout()
        } else {
            // iPhone: Tab View
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
            SidebarView()
        } content: {
            ContentPlaceholderView()
        } detail: {
            DetailPlaceholderView()
        }
    }
}

// MARK: - iPad Sidebar
struct SidebarView: View {
    @State private var selectedTab: SidebarTab? = .songs

    var body: some View {
        List(selection: $selectedTab) {
            Section {
                NavigationLink(value: SidebarTab.songs) {
                    Label("곡", systemImage: "music.note")
                        .font(.bodyLarge)
                }

                NavigationLink(value: SidebarTab.setlists) {
                    Label("콘티", systemImage: "music.note.list")
                        .font(.bodyLarge)
                }
            } header: {
                Text("라이브러리")
                    .font(.labelLarge)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .navigationTitle("Musicon")
        .tint(.accentGold)
        .navigationDestination(for: SidebarTab.self) { tab in
            switch tab {
            case .songs:
                SongListContentView()
            case .setlists:
                SetlistListContentView()
            }
        }
    }
}

enum SidebarTab: Hashable {
    case songs
    case setlists
}

// MARK: - Content Views
struct SongListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var selectedSong: Song?

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
                List(selection: $selectedSong) {
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
    @State private var selectedSetlist: Setlist?

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
                List(selection: $selectedSetlist) {
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

            Text("항목을 선택하세요")
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)

            Text("왼쪽에서 곡이나 콘티를 선택하면\n여기에 목록이 표시됩니다")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
}

struct DetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "music.note")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.accentGold.opacity(0.6))

            Text("상세 정보")
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)

            Text("목록에서 항목을 선택하면\n여기에 상세 정보가 표시됩니다")
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
