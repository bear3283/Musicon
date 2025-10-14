//
//  Song.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    @Attribute var title: String
    @Attribute var createdAt: Date
    @Attribute var updatedAt: Date

    // 음악 정보
    var tempo: Int?
    var key: String?
    var timeSignature: String?
    var notes: String?

    // 악보 이미지
    @Attribute(.externalStorage)
    var sheetMusicImages: [Data]

    // 곡 구조
    @Relationship(deleteRule: .cascade)
    var sections: [SongSection]

    // 관계 (SetlistItem에서 inverse 관리)
    var setlistItems: [SetlistItem]?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tempo: Int? = nil,
        key: String? = nil,
        timeSignature: String? = nil,
        sheetMusicImages: [Data] = [],
        sections: [SongSection] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tempo = tempo
        self.key = key
        self.timeSignature = timeSignature
        self.sheetMusicImages = sheetMusicImages
        self.sections = sections
    }

    // Validation
    func validate() throws {
        guard !title.isEmpty else {
            throw ValidationError.emptyTitle
        }

        if let tempo = tempo {
            guard tempo > 0 && tempo <= 300 else {
                throw ValidationError.invalidTempo
            }
        }
    }

    // 이미지 관리
    func addSheetMusicImage(_ image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ValidationError.imageCompressionFailed
        }

        guard sheetMusicImages.count < 10 else {
            throw ValidationError.imageLimitExceeded
        }

        sheetMusicImages.append(data)
        updatedAt = Date()
    }

    func removeSheetMusicImage(at index: Int) {
        guard index >= 0 && index < sheetMusicImages.count else { return }
        sheetMusicImages.remove(at: index)
        updatedAt = Date()
    }

    func getSheetMusicImage(at index: Int) -> UIImage? {
        guard index >= 0 && index < sheetMusicImages.count else { return nil }
        return UIImage(data: sheetMusicImages[index])
    }
}
