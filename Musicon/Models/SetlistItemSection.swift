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
    var customName: String?

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
        let baseName = type == .custom && customName != nil && !customName!.isEmpty ? customName! : type.rawValue

        if let customLabel = customLabel, !customLabel.isEmpty {
            return "\(baseName)\(customLabel)"
        }
        return baseName
    }

    // SongSection으로부터 복제하는 편의 생성자
    convenience init(from songSection: SongSection) {
        self.init(
            type: songSection.type,
            order: songSection.order,
            customLabel: songSection.customLabel,
            customName: songSection.customName
        )
    }
}
