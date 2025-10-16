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
    var customName: String?

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
        let baseName = type == .custom && customName != nil && !customName!.isEmpty ? customName! : type.rawValue

        if let customLabel = customLabel, !customLabel.isEmpty {
            return "\(baseName)\(customLabel)"
        }
        return baseName
    }
}
