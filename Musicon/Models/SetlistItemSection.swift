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
    @Attribute(.unique) var id: UUID
    var type: SectionType
    var order: Int
    var customLabel: String?

    @Relationship(inverse: \SetlistItem.sections)
    var setlistItem: SetlistItem?

    init(
        id: UUID = UUID(),
        type: SectionType,
        order: Int,
        customLabel: String? = nil
    ) {
        self.id = id
        self.type = type
        self.order = order
        self.customLabel = customLabel
    }

    var displayLabel: String {
        if let customLabel = customLabel, !customLabel.isEmpty {
            return "\(type.rawValue)\(customLabel)"
        }
        return type.rawValue
    }

    // SongSection으로부터 복제하는 편의 생성자
    convenience init(from songSection: SongSection) {
        self.init(
            type: songSection.type,
            order: songSection.order,
            customLabel: songSection.customLabel
        )
    }
}
