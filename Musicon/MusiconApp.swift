//
//  MusiconApp.swift
//  Musicon
//
//  Created by bear on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct MusiconApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            SongSection.self,
            Setlist.self,
            SetlistItem.self,
            SetlistItemSection.self
        ])

        // iCloud 동기화 활성화
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 더 자세한 에러 정보 출력
            print("❌ ModelContainer 생성 실패:")
            print("에러: \(error)")
            print("에러 설명: \(error.localizedDescription)")
            print("전체 에러 정보: \(String(describing: error))")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
