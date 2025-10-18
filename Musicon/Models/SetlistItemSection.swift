//
//  SetlistItemSection.swift
//  Musicon
//
//  Created by bear on 10/15/25.
//

import Foundation
import SwiftData

@Model
final class SetlistItemSection {
    // CloudKit 호환: .unique 제거, 기본값 추가
    var id: UUID = UUID()
    var type: SectionType? // CloudKit 호환: enum은 옵셔널로
    var order: Int = 0
    var customLabel: String?
    var customName: String?

    // CloudKit 호환: 관계는 옵셔널
    @Relationship(inverse: \SetlistItem.sections)
    var setlistItem: SetlistItem?

    init(
        id: UUID = UUID(),
        type: SectionType,
        order: Int,
        customLabel: String? = nil,
        customName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.order = order
        self.customLabel = customLabel
        self.customName = customName
    }

    var displayLabel: String {
        let actualType = type ?? .verse // 옵셔널 처리
        let baseName = actualType == .custom && customName != nil && !customName!.isEmpty ? customName! : actualType.rawValue

        if let customLabel = customLabel, !customLabel.isEmpty {
            return "\(baseName)\(customLabel)"
        }
        return baseName
    }

    // SongSection으로부터 복제하는 편의 생성자
    convenience init(from songSection: SongSection) {
        self.init(
            type: songSection.type ?? .verse, // 옵셔널 처리
            order: songSection.order,
            customLabel: songSection.customLabel,
            customName: songSection.customName
        )
    }
}
