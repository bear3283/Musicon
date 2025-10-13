//
//  Setlist.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation
import SwiftData

@Model
final class Setlist {
    @Attribute(.unique) var id: UUID
    @Attribute var title: String
    @Attribute var createdAt: Date
    @Attribute var updatedAt: Date
    var performanceDate: Date?
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var items: [SetlistItem]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        performanceDate: Date? = nil,
        notes: String? = nil,
        items: [SetlistItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.performanceDate = performanceDate
        self.notes = notes
        self.items = items
    }

    // Validation
    func validate() throws {
        guard !title.isEmpty else {
            throw ValidationError.emptyTitle
        }

        // 순서 중복 체크
        let orders = items.map { $0.order }
        guard Set(orders).count == orders.count else {
            throw ValidationError.duplicateOrder
        }
    }
}
