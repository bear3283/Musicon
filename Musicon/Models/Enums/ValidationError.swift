//
//  ValidationError.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation

enum ValidationError: LocalizedError {
    case emptyTitle
    case invalidTempo
    case duplicateOrder
    case imageCompressionFailed
    case imageLimitExceeded

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "제목을 입력해주세요"
        case .invalidTempo:
            return "올바른 BPM을 입력해주세요 (1-300)"
        case .duplicateOrder:
            return "곡 순서가 중복되었습니다"
        case .imageCompressionFailed:
            return "이미지 처리에 실패했습니다"
        case .imageLimitExceeded:
            return "악보 이미지는 최대 10장까지 추가할 수 있습니다"
        }
    }
}
