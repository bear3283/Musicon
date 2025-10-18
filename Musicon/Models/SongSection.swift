//
//  SongSection.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation
import SwiftData

@Model
final class SongSection {
    // CloudKit 호환: .unique 제거, 기본값 추가
    var id: UUID = UUID()
    var type: SectionType? // CloudKit 호환: enum은 옵셔널로
    var order: Int = 0
    var customLabel: String?
    var customName: String?

    // CloudKit 호환: 관계는 옵셔널
    @Relationship(inverse: \Song.sections)
    var song: Song?

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
}
