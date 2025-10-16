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
    @State private var showingSheetMusicView = false
    @State private var showingShareSheet = false
    @State private var currentSongIndex = 0
    @State private var showPageIndicator = true
    @State private var hideTask: Task<Void, Never>?
    @State private var pdfURL: URL?
    @State private var showingExportError = false

    var sortedItems: [SetlistItem] {
        setlist.items.sorted { $0.order < $1.order }
    }

    // 악보가 있는지 확인
    var hasSheetMusic: Bool {
        sortedItems.contains { !$0.sheetMusicImages.isEmpty }
    }

    var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.accentGold.opacity(0.6))

            Text("곡이 없습니다")
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)

            Text("곡을 추가하여 콘티를 구성하세요")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
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
            .background(Color.accentGold.opacity(0.1))
            .foregroundStyle(Color.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .accessibilityLabel("곡 추가")
        .accessibilityHint("콘티에 곡을 추가합니다")
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
        .tint(Color.accentGold)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // 공유 버튼
                    Button {
                        exportToPDF()
                    } label: {
                        Label("공유", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(Color.accentGold)
                    .accessibilityLabel("공유")
                    .accessibilityHint("콘티를 PDF로 내보내거나 공유합니다")

                    // 악보 보기 버튼 (악보가 있을 때만)
                    if hasSheetMusic {
                        Button {
                            showingSheetMusicView = true
                        } label: {
                            Label("악보 보기", systemImage: "music.note.list")
                        }
                        .foregroundStyle(Color.accentGold)
                        .accessibilityLabel("악보 보기")
                        .accessibilityHint("콘티의 모든 악보를 순서대로 봅니다")
                    }

                    // 편집 버튼
                    Button(isEditing ? "완료" : "편집") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditing.toggle()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentGold)
                    .accessibilityHint(isEditing ? "편집 모드를 종료합니다" : "편집 모드로 전환하여 곡 순서를 변경하거나 삭제할 수 있습니다")
                }
            }
        }
        .sheet(isPresented: $showingAddSong) {
            AddSongToSetlistView(setlist: setlist)
        }
        .sheet(isPresented: $showingSheetMusicView) {
            SetlistSheetMusicView(setlist: setlist)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .alert("PDF 생성 실패", isPresented: $showingExportError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("콘티를 PDF로 내보내는 데 실패했습니다. 다시 시도해주세요.")
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

    private func exportToPDF() {
        print("📤 Export to PDF button tapped")
        let pdfRenderer = SetlistPDFRenderer(setlist: setlist)
        if let url = pdfRenderer.generatePDF() {
            print("✅ PDF generated, showing share sheet")
            pdfURL = url
            showingShareSheet = true
        } else {
            print("❌ PDF generation failed, showing error alert")
            showingExportError = true
        }
    }
}

// 곡 간단 카드 (편집 모드용 - 번호, 제목, 기본 정보만)
struct SetlistSongSimpleCard: View {
    let index: Int
    let item: SetlistItem
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var accessibilityDescription: String {
        var description = "\(index)번, \(item.title)"

        var details: [String] = []
        if let key = item.key {
            details.append("코드 \(key)")
        }
        if let tempo = item.tempo {
            details.append("템포 \(tempo) BPM")
        }
        if let timeSignature = item.timeSignature {
            details.append("박자 \(timeSignature)")
        }

        if !details.isEmpty {
            description += ", " + details.joined(separator: ", ")
        }

        return description
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // 번호
            Text("\(index)")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentGold)
                .frame(width: 40)

            // 곡 정보
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // 제목
                Text(item.title)
                    .font(.titleSmall)

                // 코드, 템포, 박자
                HStack(spacing: Spacing.sm) {
                    if let key = item.key {
                        Badge(key, style: .code)
                    }

                    if let tempo = item.tempo {
                        Badge("\(tempo) BPM", style: .tempo)
                    }

                    if let timeSignature = item.timeSignature {
                        Badge(timeSignature, style: .signature)
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
            .accessibilityLabel("곡 삭제")
            .accessibilityHint("\(item.title)을(를) 콘티에서 삭제합니다")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 헤더: 번호, 제목, 삭제 버튼
            HStack(alignment: .center, spacing: Spacing.md) {
                // 번호
                Text("\(index)")
                    .font(.displaySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentGold)
                    .frame(width: 40)

                // 곡 제목
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.titleSmall)
                }

                Spacer()

                // 설정 버튼
                Button {
                    showingItemDetail = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color.accentGold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("곡 설정")
                .accessibilityHint("코드, 템포, 구조, 메모를 변경할 수 있습니다")

                // 삭제 버튼 (편집 모드에서만)
                if isEditing {
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("곡 삭제")
                    .accessibilityHint("\(item.title)을(를) 콘티에서 삭제합니다")
                }
            }

            // 곡 정보
            HStack(spacing: Spacing.sm) {
                if let key = item.key {
                    Badge(key, style: .code)
                }

                if let tempo = item.tempo {
                    Badge("\(tempo) BPM", style: .tempo)
                }

                if let timeSignature = item.timeSignature {
                    Badge(timeSignature, style: .signature)
                }

                if item.notes != nil {
                    Image(systemName: "note.text")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // 곡 구조
            if !item.sections.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("구조")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    let sortedSections = item.sections.sorted(by: { $0.order < $1.order })

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
            if !item.sheetMusicImages.isEmpty {
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
                                ForEach(Array(item.sheetMusicImages.enumerated()), id: \.offset) { index, imageData in
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

// ShareSheet (UIKit UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 Creating UIActivityViewController with \(items.count) items")
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad에서 popover 설정
        if let popoverController = controller.popoverPresentationController {
            print("📤 Configuring popover for iPad")
            popoverController.sourceView = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.rootViewController?.view
            popoverController.sourceRect = CGRect(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        } else {
            print("📤 No popover configuration needed (iPhone)")
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// PDF 생성기
class SetlistPDFRenderer {
    let setlist: Setlist

    init(setlist: Setlist) {
        self.setlist = setlist
    }

    func generatePDF() -> URL? {
        print("📄 Starting PDF generation for setlist: \(setlist.title)")

        let pdfMetaData = [
            kCGPDFContextCreator: "Musicon",
            kCGPDFContextTitle: setlist.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // A4 가로 (Landscape)
        let pageWidth: CGFloat = 842  // A4 가로
        let pageHeight: CGFloat = 595  // A4 세로
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            let margin: CGFloat = 30
            let columnWidth = (pageWidth - margin * 3) / 2  // 2등분

            let headerFont = UIFont.systemFont(ofSize: 11)
            let titleFont = UIFont.boldSystemFont(ofSize: 13)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let captionFont = UIFont.systemFont(ofSize: 12)

            let sortedItems = setlist.items.sorted { $0.order < $1.order }

            // 슬롯 배치: 각 슬롯은 곡 또는 추가 악보를 담을 수 있음
            var slots: [(item: SetlistItem, sheetIndex: Int)] = []

            for item in sortedItems {
                // 첫 번째 슬롯: 곡 정보 + 첫 악보
                slots.append((item: item, sheetIndex: 0))

                // 추가 악보들
                if item.sheetMusicImages.count > 1 {
                    for sheetIndex in 1..<item.sheetMusicImages.count {
                        slots.append((item: item, sheetIndex: sheetIndex))
                    }
                }
            }

            var slotIndex = 0

            while slotIndex < slots.count {
                context.beginPage()

                // 머리말 그리기 (각 페이지 상단)
                let headerY: CGFloat = margin

                // 콘티 제목과 공연 날짜를 한 줄에 표시
                var headerText = setlist.title
                if let performanceDate = setlist.performanceDate {
                    headerText += " | \(formatDate(performanceDate))"
                }

                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: headerFont,
                    .foregroundColor: UIColor.darkGray
                ]
                headerText.draw(at: CGPoint(x: margin, y: headerY), withAttributes: headerAttributes)

                let contentStartY = headerY + 20

                // 왼쪽 슬롯
                if slotIndex < slots.count {
                    let slot = slots[slotIndex]
                    drawSlot(
                        item: slot.item,
                        sheetIndex: slot.sheetIndex,
                        x: margin,
                        y: contentStartY,
                        width: columnWidth,
                        height: pageHeight - contentStartY - margin,
                        titleFont: titleFont,
                        bodyFont: bodyFont,
                        captionFont: captionFont,
                        isFirstSheet: slot.sheetIndex == 0,
                        setlistNotes: setlist.notes
                    )
                    slotIndex += 1
                }

                // 오른쪽 슬롯
                if slotIndex < slots.count {
                    let slot = slots[slotIndex]
                    drawSlot(
                        item: slot.item,
                        sheetIndex: slot.sheetIndex,
                        x: margin * 2 + columnWidth,
                        y: contentStartY,
                        width: columnWidth,
                        height: pageHeight - contentStartY - margin,
                        titleFont: titleFont,
                        bodyFont: bodyFont,
                        captionFont: captionFont,
                        isFirstSheet: slot.sheetIndex == 0,
                        setlistNotes: setlist.notes
                    )
                    slotIndex += 1
                }
            }
        }

        // 임시 파일로 저장
        let fileName = "\(setlist.title).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        print("📄 PDF data size: \(data.count) bytes")
        print("📄 Attempting to save to: \(tempURL.path)")

        do {
            try data.write(to: tempURL)
            print("✅ PDF saved successfully at: \(tempURL.path)")
            return tempURL
        } catch {
            print("❌ PDF 저장 실패: \(error.localizedDescription)")
            return nil
        }
    }

    private func drawSlot(
        item: SetlistItem,
        sheetIndex: Int,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        titleFont: UIFont,
        bodyFont: UIFont,
        captionFont: UIFont,
        isFirstSheet: Bool,
        setlistNotes: String?
    ) {
        var currentY = y

        // 첫 번째 악보일 때만 곡 정보 표시
        if isFirstSheet {
            let sortedItems = item.setlist?.items.sorted { $0.order < $1.order } ?? []
            let songNumber = (sortedItems.firstIndex(where: { $0.id == item.id }) ?? 0) + 1

            // 1행: 번호 + 제목 + 기본 정보
            var firstLine = "\(songNumber). \(item.title)"

            var infoText = ""
            if let key = item.key {
                infoText += "코드: \(key)"
            }
            if let tempo = item.tempo {
                if !infoText.isEmpty { infoText += " | " }
                infoText += "템포: \(tempo) BPM"
            }
            if let timeSignature = item.timeSignature {
                if !infoText.isEmpty { infoText += " | " }
                infoText += "박자: \(timeSignature)"
            }

            if !infoText.isEmpty {
                firstLine += "  (\(infoText))"
            }

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            firstLine.draw(at: CGPoint(x: x, y: currentY), withAttributes: titleAttributes)
            currentY += 18

            // 2행: 곡 구조
            let sortedSections = item.sections.sorted { $0.order < $1.order }
            if !sortedSections.isEmpty {
                let structureText = "구조: " + sortedSections.map { $0.displayLabel }.joined(separator: " → ")
                let structureAttributes: [NSAttributedString.Key: Any] = [
                    .font: captionFont,
                    .foregroundColor: UIColor.darkGray
                ]
                structureText.draw(at: CGPoint(x: x, y: currentY), withAttributes: structureAttributes)
                currentY += 18
            }

            // 곡 정보와 악보 사이 간격
            currentY += 5
        }

        // 악보 이미지
        var imageEndY = currentY
        if sheetIndex < item.sheetMusicImages.count {
            let imageData = item.sheetMusicImages[sheetIndex]
            if let uiImage = UIImage(data: imageData) {
                // 콘티 메모를 위한 공간 예약 (메모가 있을 경우)
                let notesHeight: CGFloat = (setlistNotes != nil && !setlistNotes!.isEmpty) ? 40 : 0
                let availableHeight = y + height - currentY - notesHeight
                let imageRect = CGRect(x: x, y: currentY, width: width, height: availableHeight)

                // 이미지를 비율을 유지하면서 영역에 맞게 조정
                let imageAspect = uiImage.size.width / uiImage.size.height
                let rectAspect = imageRect.width / imageRect.height

                var drawRect = imageRect
                if imageAspect > rectAspect {
                    // 이미지가 더 넓음 - 너비에 맞춤
                    let newHeight = imageRect.width / imageAspect
                    drawRect = CGRect(
                        x: imageRect.minX,
                        y: imageRect.minY,
                        width: imageRect.width,
                        height: newHeight
                    )
                } else {
                    // 이미지가 더 높음 - 높이에 맞춤
                    let newWidth = imageRect.height * imageAspect
                    drawRect = CGRect(
                        x: imageRect.minX,
                        y: imageRect.minY,
                        width: newWidth,
                        height: imageRect.height
                    )
                }

                uiImage.draw(in: drawRect)
                imageEndY = drawRect.maxY
            }
        }

        // 콘티 메모 (악보 이미지 밑에 표시)
        if let notes = setlistNotes, !notes.isEmpty {
            let notesY = imageEndY + 10
            let notesText = "메모: \(notes)"
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: UIColor.darkGray
            ]
            let notesRect = CGRect(x: x, y: notesY, width: width, height: 30)
            notesText.draw(in: notesRect, withAttributes: notesAttributes)
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
