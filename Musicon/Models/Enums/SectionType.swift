//
//  SectionType.swift
//  Musicon
//
//  Created by bear on 10/12/25.
//

import Foundation
import SwiftUI

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

    var color: Color {
        switch self {
        case .verse: return Color(red: 0.2, green: 0.6, blue: 0.8) // 진한 하늘색
        case .chorus: return Color(red: 0.9, green: 0.7, blue: 0.2) // 진한 노랑
        case .preChorus: return Color(red: 0.9, green: 0.3, blue: 0.5) // 진한 핑크
        case .bridge: return Color(red: 0.9, green: 0.5, blue: 0.2) // 진한 주황
        case .intro: return Color(red: 0.2, green: 0.4, blue: 0.9) // 진한 파랑
        case .outro: return Color(red: 0.2, green: 0.7, blue: 0.4) // 진한 초록
        case .instrumental: return Color(red: 0.6, green: 0.2, blue: 0.8) // 진한 보라
        case .custom: return Color(red: 0.5, green: 0.5, blue: 0.5) // 진한 회색
        }
    }
}
