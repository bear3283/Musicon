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
                HStack(spacing: 16) {
                    // 공유 버튼
                    Button {
                        exportToPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
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
        let pdfRenderer = SetlistPDFRenderer(setlist: setlist)
        if let url = pdfRenderer.generatePDF() {
            pdfURL = url
            showingShareSheet = true
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
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
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
        let pdfMetaData = [
            kCGPDFContextCreator: "Musicon",
            kCGPDFContextTitle: setlist.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headingFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let captionFont = UIFont.systemFont(ofSize: 10)

            var yPosition: CGFloat = 50

            // 제목
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleText = setlist.title
            titleText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // 공연 날짜
            if let performanceDate = setlist.performanceDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                let dateText = "공연 날짜: \(dateFormatter.string(from: performanceDate))"
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ]
                dateText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30
            }

            // 메모
            if let notes = setlist.notes, !notes.isEmpty {
                let notesText = "메모: \(notes)"
                let notesAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ]
                let notesRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 60)
                notesText.draw(in: notesRect, withAttributes: notesAttributes)
                yPosition += 70
            }

            // 구분선
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 50, y: yPosition))
            linePath.addLine(to: CGPoint(x: pageWidth - 50, y: yPosition))
            UIColor.lightGray.setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            yPosition += 20

            // 곡 목록 헤더
            let headerText = "곡 목록 (\(setlist.items.count)곡)"
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: UIColor.black
            ]
            headerText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
            yPosition += 30

            // 곡 목록
            let sortedItems = setlist.items.sorted { $0.order < $1.order }
            for (index, item) in sortedItems.enumerated() {
                // 페이지 넘김 체크
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 50
                }

                let songNumber = "\(index + 1)."
                let songTitle = item.title

                // 번호와 제목
                let numberAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.systemBlue
                ]
                songNumber.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: numberAttributes)

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                songTitle.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: titleAttributes)
                yPosition += 20

                // 곡 정보 (코드, 템포, 박자)
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
                    let infoAttributes: [NSAttributedString.Key: Any] = [
                        .font: captionFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    infoText.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: infoAttributes)
                    yPosition += 15
                }

                // 곡 구조
                let sortedSections = item.sections.sorted { $0.order < $1.order }
                if !sortedSections.isEmpty {
                    let structureText = "구조: " + sortedSections.map { $0.displayLabel }.joined(separator: " → ")
                    let structureAttributes: [NSAttributedString.Key: Any] = [
                        .font: captionFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    structureText.draw(at: CGPoint(x: 80, y: yPosition), withAttributes: structureAttributes)
                    yPosition += 15
                }

                // 메모
                if let notes = item.notes, !notes.isEmpty {
                    let notesText = "메모: \(notes)"
                    let notesAttributes: [NSAttributedString.Key: Any] = [
                        .font: captionFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    let notesRect = CGRect(x: 80, y: yPosition, width: pageWidth - 130, height: 40)
                    notesText.draw(in: notesRect, withAttributes: notesAttributes)
                    yPosition += 45
                } else {
                    yPosition += 10
                }

                yPosition += 10
            }
        }

        // 임시 파일로 저장
        let fileName = "\(setlist.title).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDF 저장 실패: \(error)")
            return nil
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
