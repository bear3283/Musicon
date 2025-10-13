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
    @Attribute(.unique) var id: UUID
    var order: Int

    @Relationship(inverse: \Setlist.items)
    var setlist: Setlist?

    @Relationship(inverse: \Song.setlistItems)
    var song: Song

    // 콘티별 커스터마이징
    var customKey: String?
    var customTempo: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        order: Int,
        song: Song,
        customKey: String? = nil,
        customTempo: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.song = song
        self.customKey = customKey
        self.customTempo = customTempo
        self.notes = notes
    }

    // 표시할 키 (커스텀이 있으면 커스텀, 없으면 원곡)
    var displayKey: String? {
        customKey ?? song.key
    }

    // 표시할 템포 (커스텀이 있으면 커스텀, 없으면 원곡)
    var displayTempo: Int? {
        customTempo ?? song.tempo
    }
}
