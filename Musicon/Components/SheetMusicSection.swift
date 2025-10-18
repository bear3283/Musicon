//
//  SheetMusicSection.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct SheetMusicSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let song: Song

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageIndex: Int?
    @State private var deletingImageIndex: Int?
    @State private var notes: String = ""
    @State private var showAddImageOptions = false
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    @FocusState private var isNotesFocused: Bool

    @State private var showingImageLimitError = false
    @State private var isLoadingImages = false

    var body: some View {                        
        VStack(alignment: .leading, spacing: 12) {
            Text("악보")
                .font(.headline)
                .contentShape(Rectangle())
                .onTapGesture {
                    isNotesFocused = false
                }

            if song.sheetMusicImages.isEmpty {
                // 빈 상태
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("악보 이미지가 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("악보 사진을 추가하여 연습할 수 있습니다")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .contentShape(Rectangle())
                .onTapGesture {
                    isNotesFocused = false
                }
            } else {
                // 이미지 그리드
                GeometryReader { geometry in
                    // iPad에서 더 큰 크기로 표시
                    let isIPad = horizontalSizeClass == .regular
                    let isLandscape = geometry.size.width > geometry.size.height

                    // iPad: 가로 90%, 세로 85% | iPhone: 80%
                    let widthRatio: CGFloat = isIPad ? (isLandscape ? 0.90 : 0.85) : 0.80
                    let imageWidth: CGFloat = geometry.size.width * widthRatio

                    // iPad: 화면 높이의 거의 전부 사용 (90-95%) | iPhone: 85%
                    let heightRatio: CGFloat = isIPad ? (isLandscape ? 0.92 : 0.95) : 0.85
                    let imageHeight: CGFloat = geometry.size.height * heightRatio
                    let spacing: CGFloat = 16

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: spacing) {
                            ForEach(Array(song.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                                if let uiImage = UIImage(data: imageData) {
                                    Button {
                                        isNotesFocused = false
                                        selectedImageIndex = index
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: imageWidth)
                                            .frame(maxHeight: imageHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    deletingImageIndex = index
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .background(Circle().fill(.red))
                                                }
                                                .padding(4)
                                                .accessibilityLabel("악보 이미지 삭제")
                                                .accessibilityHint("\(index + 1)번 악보 이미지를 삭제합니다")
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("악보 이미지 \(index + 1)")
                                    .accessibilityHint("크게 보려면 누르세요")
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
                .frame(height: horizontalSizeClass == .regular ? 600 : 420)
            }

            // 악보 추가 버튼
            Button {
                isNotesFocused = false
                showAddImageOptions = true
            } label: {
                HStack {
                    if isLoadingImages {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("이미지 로딩 중...")
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("악보 추가")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentGold.opacity(0.1))
                .foregroundStyle(Color.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoadingImages)
            .accessibilityLabel(isLoadingImages ? "이미지 로딩 중" : "악보 추가")
            .accessibilityHint(isLoadingImages ? "이미지를 불러오고 있습니다" : "사진 라이브러리 또는 파일에서 악보 이미지를 선택합니다")

            // 메모 섹션
            VStack(alignment: .leading, spacing: 8) {
                Text("메모")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isNotesFocused = false
                    }

                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .focused($isNotesFocused)
                    .onChange(of: isNotesFocused) { _, isFocused in
                        if !isFocused {
                            saveNotes()
                        }
                    }
                    .accessibilityLabel("메모")
                    .accessibilityHint("곡에 대한 메모를 입력하세요")
            }
        }
        .onAppear {
            notes = song.notes ?? ""
        }
        .alert("악보 이미지 삭제", isPresented: Binding(
            get: { deletingImageIndex != nil },
            set: { if !$0 { deletingImageIndex = nil } }
        )) {
            Button("취소", role: .cancel) {
                deletingImageIndex = nil
            }
            Button("삭제", role: .destructive) {
                if let index = deletingImageIndex {
                    deleteImage(at: index)
                    deletingImageIndex = nil
                }
            }
        } message: {
            Text("이 악보 이미지를 삭제하시겠습니까?")
        }
        .background {
            if horizontalSizeClass == .regular {
                // iPad: 전체화면 모달
                Color.clear
                    .fullScreenCover(item: Binding(
                        get: { selectedImageIndex.map { ImageIndex(value: $0) } },
                        set: { selectedImageIndex = $0?.value }
                    )) { imageIndex in
                        ImageViewer(song: song, images: song.sheetMusicImages, currentIndex: imageIndex.value)
                    }
            } else {
                // iPhone: sheet with large detent
                Color.clear
                    .sheet(item: Binding(
                        get: { selectedImageIndex.map { ImageIndex(value: $0) } },
                        set: { selectedImageIndex = $0?.value }
                    )) { imageIndex in
                        ImageViewer(song: song, images: song.sheetMusicImages, currentIndex: imageIndex.value)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.hidden)
                    }
            }
        }
        .confirmationDialog("악보 이미지 추가", isPresented: $showAddImageOptions) {
            Button("사진 라이브러리에서 선택") {
                showPhotosPicker = true
            }
            Button("파일에서 선택") {
                showFileImporter = true
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $showPhotosPicker) {
            PhotosPickerView(selectedItems: $selectedItems, song: song, modelContext: modelContext, showingImageLimitError: $showingImageLimitError, isLoadingImages: $isLoadingImages)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await loadImagesFromFiles(result: result)
            }
        }
        .alert("이미지 제한 초과", isPresented: $showingImageLimitError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("악보 이미지는 최대 10장까지 추가할 수 있습니다.\n현재 \(song.sheetMusicImages.count)장이 저장되어 있습니다.")
        }
    }

    private func deleteImage(at index: Int) {
        song.sheetMusicImages.remove(at: index)
        song.updatedAt = Date()
        try? modelContext.save()
    }

    private func saveNotes() {
        song.notes = notes.isEmpty ? nil : notes
        song.updatedAt = Date()
        try? modelContext.save()
    }

    private func loadImagesFromFiles(result: Result<[URL], Error>) async {
        guard let urls = try? result.get() else { return }

        await MainActor.run {
            isLoadingImages = true
        }

        var addedCount = 0
        var limitExceeded = false

        for url in urls {
            // Check limit before adding
            await MainActor.run {
                if song.sheetMusicImages.count >= 10 {
                    limitExceeded = true
                }
            }

            if limitExceeded {
                break
            }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            // Load image data
            if let data = try? Data(contentsOf: url) {
                await MainActor.run {
                    song.sheetMusicImages.append(data)
                    addedCount += 1
                }
            }
        }

        await MainActor.run {
            if limitExceeded {
                showingImageLimitError = true
            }
            song.updatedAt = Date()
            try? modelContext.save()
            isLoadingImages = false
        }
    }
}

struct ImageIndex: Identifiable {
    let id = UUID()
    let value: Int
}

struct PhotosPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedItems: [PhotosPickerItem]
    let song: Song
    let modelContext: ModelContext
    @Binding var showingImageLimitError: Bool
    @Binding var isLoadingImages: Bool

    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentGold)

                        Text("사진 선택")
                            .font(.headline)

                        Text("최대 10장까지 선택 가능합니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("사진 라이브러리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                if !newItems.isEmpty {
                    Task {
                        await loadImages(from: newItems)
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        await MainActor.run {
            isLoadingImages = true
        }

        var limitExceeded = false

        for item in items {
            // Check limit before adding
            let currentCount = await MainActor.run {
                return song.sheetMusicImages.count
            }

            if currentCount >= 10 {
                limitExceeded = true
                break
            }

            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    song.sheetMusicImages.append(data)
                }
            }
        }

        await MainActor.run {
            if limitExceeded {
                showingImageLimitError = true
            }
            song.updatedAt = Date()
            try? modelContext.save()
            selectedItems = []
            isLoadingImages = false
        }
    }
}

struct ImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let song: Song
    let images: [Data]
    @State var currentIndex: Int
    @State private var showPageIndicator = true
    @State private var hideTask: Task<Void, Never>?

    var sortedSections: [SongSection] {
        (song.sections ?? []).sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                    if let uiImage = UIImage(data: imageData) {
                        ZoomableImageView(image: uiImage)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .navigationTitle("악보 \(currentIndex + 1)/\(images.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if !sortedSections.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("구조")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

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
                    .padding()
                    .background(Color(.systemBackground).opacity(0.95))
                }
            }
            .overlay(alignment: .bottom) {
                if showPageIndicator {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.opacity)
                }
            }
            .onChange(of: currentIndex) { _, _ in
                showIndicatorTemporarily()
            }
            .onAppear {
                showIndicatorTemporarily()
            }
        }
    }

    private func showIndicatorTemporarily() {
        // Cancel existing hide task
        hideTask?.cancel()

        // Show indicator
        withAnimation {
            showPageIndicator = true
        }

        // Hide after 2 seconds
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

struct ZoomableImageView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width * max(1, scale),
                       height: geometry.size.height * max(1, scale))
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1), 4)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1 {
                                withAnimation(.spring()) {
                                    scale = 1
                                    offset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: scale > 1 ? 0 : 50)
                        .onChanged { value in
                            if scale > 1 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            if scale > 1 {
                                lastOffset = offset
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .background(Color.black)
    }
}

#Preview {
    SheetMusicSection(song: Song(title: "Test"))
        .padding()
        .modelContainer(for: Song.self, inMemory: true)
}
