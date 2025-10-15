//
//  SetlistSheetMusicView.swift
//  Musicon
//
//  Created by bear on 10/15/25.
//

import SwiftUI
import SwiftData

struct SetlistSheetMusicView: View {
    @Environment(\.dismiss) private var dismiss
    let setlist: Setlist

    @State private var currentPage = 0
    @State private var showPageIndicator = true
    @State private var hideTask: Task<Void, Never>?

    // 모든 악보 이미지를 순서대로 수집
    var allSheetMusicData: [(item: SetlistItem, order: Int, imageIndex: Int, imageData: Data)] {
        let sortedItems = setlist.items.sorted { $0.order < $1.order }
        var result: [(SetlistItem, Int, Int, Data)] = []

        for item in sortedItems {
            let order = item.order + 1

            for (index, imageData) in item.sheetMusicImages.enumerated() {
                result.append((item, order, index, imageData))
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            if allSheetMusicData.isEmpty {
                // 악보가 없을 때
                ContentUnavailableView {
                    Label("악보가 없습니다", systemImage: "music.note.list")
                } description: {
                    Text("곡에 악보를 추가해주세요")
                }
            } else {
                TabView(selection: $currentPage) {
                    ForEach(Array(allSheetMusicData.enumerated()), id: \.offset) { index, data in
                        SheetMusicPageView(
                            item: data.item,
                            songOrder: data.order,
                            imageIndex: data.imageIndex,
                            totalImagesInSong: data.item.sheetMusicImages.count,
                            imageData: data.imageData,
                            currentPage: index + 1,
                            totalPages: allSheetMusicData.count
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
                .onChange(of: currentPage) { _, _ in
                    showIndicatorTemporarily()
                }
                .onAppear {
                    showIndicatorTemporarily()
                }
                .overlay(alignment: .bottom) {
                    // 페이지 인디케이터
                    if showPageIndicator {
                        HStack(spacing: 12) {
                        // 이전 버튼
                        Button {
                            withAnimation {
                                if currentPage > 0 {
                                    currentPage -= 1
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(currentPage == 0)
                        .opacity(currentPage == 0 ? 0.3 : 1.0)

                        // 페이지 번호
                        Text("\(currentPage + 1) / \(allSheetMusicData.count)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())

                        // 다음 버튼
                        Button {
                            withAnimation {
                                if currentPage < allSheetMusicData.count - 1 {
                                    currentPage += 1
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(currentPage == allSheetMusicData.count - 1)
                        .opacity(currentPage == allSheetMusicData.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.bottom, 50)
                    .transition(.opacity)
                    }
                }
                .navigationTitle("악보 보기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("완료") {
                            dismiss()
                        }
                    }
                }
            }
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

// 개별 악보 페이지 뷰
struct SheetMusicPageView: View {
    let item: SetlistItem
    let songOrder: Int
    let imageIndex: Int
    let totalImagesInSong: Int
    let imageData: Data
    let currentPage: Int
    let totalPages: Int

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var sortedSections: [SetlistItemSection] {
        item.sections.sorted { $0.order < $1.order }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 곡 정보 헤더
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(songOrder).")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text(item.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)

                            Spacer()

                            if totalImagesInSong > 1 {
                                Text("악보 \(imageIndex + 1)/\(totalImagesInSong)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)

                        // 곡 기본 정보
                        HStack(spacing: 8) {
                            if let key = item.key {
                                Text(key)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.3))
                                    .clipShape(Capsule())
                            }

                            if let tempo = item.tempo {
                                Text("\(tempo) BPM")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.3))
                                    .clipShape(Capsule())
                            }

                            if let timeSignature = item.timeSignature {
                                Text(timeSignature)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.3))
                                    .clipShape(Capsule())
                            }

                            Spacer()
                        }
                        .padding(.horizontal)

                        // 곡 구조
                        if !sortedSections.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(sortedSections.enumerated()), id: \.element.id) { index, section in
                                        HStack(spacing: 3) {
                                            Text(section.displayLabel)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.white.opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))

                                            if index < sortedSections.count - 1 {
                                                Image(systemName: "arrow.right")
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)

                    // 악보 이미지
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 4.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 1.0 {
                                            withAnimation(.spring(response: 0.3)) {
                                                scale = 1.0
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: scale > 1.0 ? 0 : 1000)
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        if scale > 1.0 {
                                            lastOffset = offset
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(response: 0.3)) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.0
                                    }
                                }
                            }
                    }

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, Setlist.self, SetlistItem.self, SetlistItemSection.self, configurations: config)

    let song1 = Song(title: "Amazing Grace", tempo: 120, key: "C", timeSignature: "4/4")
    let song2 = Song(title: "How Great Thou Art", tempo: 100, key: "G", timeSignature: "4/4")

    let setlist = Setlist(title: "주일 예배", performanceDate: Date())

    let item1 = SetlistItem(order: 0, cloneFrom: song1)
    item1.setlist = setlist
    setlist.items.append(item1)

    let item2 = SetlistItem(order: 1, cloneFrom: song2)
    item2.setlist = setlist
    setlist.items.append(item2)

    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(setlist)
    container.mainContext.insert(item1)
    container.mainContext.insert(item2)

    return SetlistSheetMusicView(setlist: setlist)
        .modelContainer(container)
}
