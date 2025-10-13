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
    @Attribute(.unique) var id: UUID
    var type: SectionType
    var order: Int
    var customLabel: String?

    @Relationship(inverse: \Song.sections)
    var song: Song?

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
}
