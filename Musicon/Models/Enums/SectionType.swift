//
//  SectionType.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation

enum SectionType: String, Codable, CaseIterable, Identifiable {
    case verse = "V"
    case chorus = "C"
    case preChorus = "P"
    case bridge = "B"
    case intro = "I"
    case outro = "O"
    case instrumental = "Inst"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .verse: return "벌스"
        case .chorus: return "코러스"
        case .preChorus: return "프리코러스"
        case .bridge: return "브릿지"
        case .intro: return "인트로"
        case .outro: return "아웃트로"
        case .instrumental: return "간주"
        case .custom: return "커스텀"
        }
    }
}
