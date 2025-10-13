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
    let song: Song

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("악보")
                .font(.headline)

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
            } else {
                // 이미지 그리드
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(song.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Button {
                                    selectedImageIndex = index
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                deleteImage(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(.red))
                                            }
                                            .padding(4)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // 악보 추가 버튼
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("악보 추가")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadImages(from: newItems)
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedImageIndex.map { ImageIndex(value: $0) } },
            set: { selectedImageIndex = $0?.value }
        )) { imageIndex in
            ImageViewer(images: song.sheetMusicImages, currentIndex: imageIndex.value)
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    song.sheetMusicImages.append(data)
                }
            }
        }

        await MainActor.run {
            song.updatedAt = Date()
            try? modelContext.save()
            selectedItems = []
        }
    }

    private func deleteImage(at index: Int) {
        song.sheetMusicImages.remove(at: index)
        song.updatedAt = Date()
        try? modelContext.save()
    }
}

struct ImageIndex: Identifiable {
    let id = UUID()
    let value: Int
}

struct ImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let images: [Data]
    @State var currentIndex: Int

    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                    if let uiImage = UIImage(data: imageData) {
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("악보 \(currentIndex + 1)/\(images.count)")
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

#Preview {
    SheetMusicSection(song: Song(title: "Test"))
        .padding()
        .modelContainer(for: Song.self, inMemory: true)
}
