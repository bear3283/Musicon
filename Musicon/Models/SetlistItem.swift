//
//  SetlistItem.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation
import SwiftData

@Model
final class SetlistItem: Identifiable {
    // CloudKit 호환: .unique 제거, 기본값 추가
    var id: UUID = UUID()
    var order: Int = 0

    // CloudKit 호환: 관계는 옵셔널
    @Relationship(inverse: \Setlist.items)
    var setlist: Setlist?

    // 원곡 참조 (옵셔널 - 원곡이 삭제되어도 콘티 아이템은 유지)
    @Relationship(inverse: \Song.setlistItems)
    var originalSong: Song?

    // 복제된 곡 데이터 (콘티별로 독립적으로 수정 가능)
    // CloudKit 호환: 기본값 추가
    var title: String = ""
    var key: String?
    var tempo: Int?
    var timeSignature: String?
    var notes: String?

    // 복제된 악보 이미지 - CloudKit 호환: 빈 배열 기본값
    @Attribute(.externalStorage)
    var sheetMusicImages: [Data] = []

    // 복제된 곡 구조 - CloudKit 호환: 관계는 옵셔널 배열로
    @Relationship(deleteRule: .cascade)
    var sections: [SetlistItemSection]?

    init(
        id: UUID = UUID(),
        order: Int,
        originalSong: Song? = nil,
        title: String,
        key: String? = nil,
        tempo: Int? = nil,
        timeSignature: String? = nil,
        notes: String? = nil,
        sheetMusicImages: [Data] = [],
        sections: [SetlistItemSection]? = nil
    ) {
        self.id = id
        self.order = order
        self.originalSong = originalSong
        self.title = title
        self.key = key
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.notes = notes
        self.sheetMusicImages = sheetMusicImages
        self.sections = sections
    }

    // Song으로부터 복제하는 편의 생성자
    convenience init(order: Int, cloneFrom song: Song) {
        // 섹션 복제
        let clonedSections = (song.sections ?? []).map { SetlistItemSection(from: $0) }

        self.init(
            order: order,
            originalSong: song,
            title: song.title,
            key: song.key,
            tempo: song.tempo,
            timeSignature: song.timeSignature,
            notes: nil, // 콘티 메모는 비워둠
            sheetMusicImages: song.sheetMusicImages,
            sections: clonedSections
        )
    }
}
