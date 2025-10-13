# 🎵 Musicon - 음악 콘티 관리 시스템

음악 공연을 위한 곡 관리 및 세트리스트(콘티) 관리 iOS 앱

## 📱 프로젝트 개요

**플랫폼**: iOS 17+
**프레임워크**: SwiftUI + SwiftData
**아키텍처**: MVVM + Repository Pattern
**개발 기간**: 10-15일 (Phase 1-6)

### 핵심 기능

- **곡 관리**: 곡 생성, 수정, 삭제 및 음악 정보 관리
- **악보 관리**: 악보 이미지 추가 및 갤러리 뷰
- **곡 구조**: 곡의 구성 요소 관리 (Verse, Chorus, Bridge 등)
- **콘티 관리**: 세트리스트 생성 및 관리
- **곡 연결**: 콘티에 곡 추가, 순서 변경, 커스터마이징

---

## 🏗️ 시스템 아키텍처

### 1. 계층 구조 (Layered Architecture)

```
┌─────────────────────────────────────────┐
│        PRESENTATION LAYER               │
│  (Views, ViewModels)                    │
│  - SongListView                         │
│  - SongDetailView                       │
│  - SetlistView                          │
│  - SetlistDetailView                    │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│         BUSINESS LOGIC LAYER            │
│  (Services, Use Cases)                  │
│  - SongService                          │
│  - SetlistService                       │
│  - ValidationService                    │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│          DATA LAYER                     │
│  (Models, Repositories)                 │
│  - Song, Setlist, SetlistItem           │
│  - SongSection                          │
│  - SwiftData ModelContainer             │
└─────────────────────────────────────────┘
```

### 2. 도메인 모델

```
┌──────────────┐         ┌──────────────────┐
│    Song      │◄───────►│  SetlistItem     │
│  (곡)        │  many    │  (콘티 내 곡)    │
└──────────────┘         └──────────────────┘
      ▲                          │
      │                          ▼
      │                  ┌──────────────┐
      │                  │   Setlist    │
      │                  │   (콘티)      │
      │                  └──────────────┘
      │
┌──────────────┐
│ SongSection  │
│ (곡 구조)     │
└──────────────┘
```

---

## 📊 데이터 모델

### Song (곡)

| 속성 | 타입 | 설명 |
|------|------|------|
| id | UUID | 고유 식별자 |
| title | String | 곡 제목 |
| tempo | Int? | BPM (템포) |
| key | String? | 조 (C, D, Em, etc.) |
| timeSignature | String? | 박자 (4/4, 3/4, etc.) |
| capo | Int? | 카포 위치 (0-12) |
| sheetMusicImages | [Data] | 악보 이미지 (최대 10장) |
| sections | [SongSection] | 곡 구조 |
| createdAt | Date | 생성 시간 |
| updatedAt | Date | 수정 시간 |

### SongSection (곡 구조)

| 속성 | 타입 | 설명 |
|------|------|------|
| id | UUID | 고유 식별자 |
| type | SectionType | 섹션 타입 (V, C, Pre, B, etc.) |
| order | Int | 순서 |
| customLabel | String? | 커스텀 레이블 ("1", "2", etc.) |

**SectionType Enum**:
- `verse` (V) - 벌스
- `chorus` (C) - 코러스
- `preChorus` (Pre) - 프리코러스
- `bridge` (B) - 브릿지
- `intro` (I) - 인트로
- `outro` (O) - 아웃트로
- `instrumental` (Inst) - 간주
- `custom` - 커스텀

### Setlist (콘티)

| 속성 | 타입 | 설명 |
|------|------|------|
| id | UUID | 고유 식별자 |
| title | String | 콘티 제목 |
| performanceDate | Date? | 공연 날짜 |
| notes | String? | 메모 |
| items | [SetlistItem] | 콘티 내 곡 목록 |
| createdAt | Date | 생성 시간 |
| updatedAt | Date | 수정 시간 |

### SetlistItem (콘티 내 곡)

| 속성 | 타입 | 설명 |
|------|------|------|
| id | UUID | 고유 식별자 |
| order | Int | 콘티 내 순서 |
| song | Song | 참조 곡 |
| customKey | String? | 이 콘티에서만 사용하는 키 |
| customTempo | Int? | 이 콘티에서만 사용하는 템포 |
| notes | String? | 콘티별 메모 |

### 관계 설계

```
Song (1) ←──────→ (N) SetlistItem (N) ←──────→ (1) Setlist
         many-to-many through SetlistItem

Song (1) ────→ (N) SongSection
         one-to-many, cascade delete
```

---

## 🔌 Service Layer API

### SongService

**곡 관리**
- `createSong(title:tempo:key:timeSignature:capo:)` → Song
- `fetchAllSongs(sortBy:)` → [Song]
- `searchSongs(query:)` → [Song]
- `fetchSong(by:)` → Song?
- `updateSong(_:title:tempo:key:timeSignature:capo:)`
- `deleteSong(_:)`

**곡 구조 관리**
- `addSection(to:type:customLabel:)`
- `reorderSections(in:from:to:)`
- `removeSection(_:from:)`

**악보 이미지 관리**
- `addSheetMusicImage(to:image:)`
- `removeSheetMusicImage(from:at:)`

**정렬 옵션**
- `recentlyCreated` - 최근 생성순
- `recentlyUpdated` - 최근 수정순
- `titleAscending` - 제목 오름차순
- `titleDescending` - 제목 내림차순

### SetlistService

**콘티 관리**
- `createSetlist(title:performanceDate:notes:)` → Setlist
- `fetchAllSetlists(sortBy:)` → [Setlist]
- `searchSetlists(query:)` → [Setlist]
- `fetchSetlist(by:)` → Setlist?
- `updateSetlist(_:title:performanceDate:notes:)`
- `deleteSetlist(_:)`

**콘티 곡 관리**
- `addSong(_:to:customKey:customTempo:notes:)`
- `removeSong(_:from:)`
- `reorderSongs(in:from:to:)`
- `updateSetlistItem(_:customKey:customTempo:notes:)`
- `getSongsInOrder(for:)` → [SetlistItem]

**정렬 옵션**
- `recentlyCreated` - 최근 생성순
- `recentlyUpdated` - 최근 수정순
- `performanceDate` - 공연 날짜순
- `titleAscending` - 제목 오름차순

---

## 🎨 UI/UX 구조

### 화면 구조

```
RootView (TabView)
├── Songs Tab
│   ├── SongListView
│   │   ├── SearchBar
│   │   ├── SortPicker
│   │   └── SongRow (List)
│   │       → SongDetailView
│   │           ├── SongInfoSection
│   │           ├── SheetMusicSection
│   │           └── SongStructureSection
│   └── CreateSongView (Sheet)
│
└── Setlists Tab
    ├── SetlistListView
    │   ├── SearchBar
    │   ├── SortPicker
    │   └── SetlistRow (List)
    │       → SetlistDetailView
    │           ├── SetlistInfoSection
    │           ├── SongListSection
    │           │   ├── SetlistItemRow (Reorderable)
    │           │   └── AddSongButton
    │           │       → SongPickerView
    │           └── SetlistActions
    └── CreateSetlistView (Sheet)
```

### 주요 컴포넌트

- **SongRow**: 곡 목록 아이템 (제목, 키, 템포, 수정일)
- **SetlistRow**: 콘티 목록 아이템 (제목, 곡 수, 공연 날짜)
- **SetlistItemRow**: 콘티 내 곡 아이템 (곡 정보, 순서, 커스텀 설정)
- **SongInfoSection**: 곡 기본 정보 섹션
- **SheetMusicSection**: 악보 이미지 갤러리
- **SongStructureSection**: 곡 구조 관리 섹션

---

## 🗺️ 구현 로드맵

### Phase 1: 기초 인프라 구축 (1-2일)

**목표**: 데이터 모델과 기본 구조 구축

- [ ] Song 모델 구현
- [ ] SongSection 모델 구현
- [ ] Setlist 모델 구현
- [ ] SetlistItem 모델 구현
- [ ] Validation 로직 구현
- [ ] SongService 구현
- [ ] SetlistService 구현
- [ ] 기본 TabView 구조 생성

**완료 조건**:
- ✅ 모든 모델이 SwiftData로 정의됨
- ✅ CRUD 작업이 Service에서 정상 작동
- ✅ 기본 앱 구조 실행 가능

### Phase 2: 곡 관리 기능 (2-3일)

**목표**: 곡 생성, 수정, 삭제, 조회 기능 완성

- [ ] SongListView 구현
- [ ] SongRow 컴포넌트
- [ ] 검색/정렬 기능
- [ ] CreateSongView 구현
- [ ] SongDetailView 구현
- [ ] SongInfoSection 구현
- [ ] SongStructureSection 구현
- [ ] 섹션 추가/삭제/순서변경

**완료 조건**:
- ✅ 곡 CRUD 기능 완전 동작
- ✅ 곡 구조 관리 기능 동작
- ✅ UI 인터랙션 정상 작동

### Phase 3: 악보 이미지 관리 (1-2일)

**목표**: 이미지 추가, 보기, 삭제 기능

- [ ] PHPickerViewController 통합
- [ ] SheetMusicSection 구현
- [ ] 이미지 그리드 뷰
- [ ] 이미지 상세 보기
- [ ] 이미지 삭제 기능

**완료 조건**:
- ✅ 이미지 추가/삭제 동작
- ✅ 이미지가 SwiftData에 저장됨
- ✅ 이미지 뷰어 동작

### Phase 4: 콘티 관리 기능 (2-3일)

**목표**: 콘티 생성, 수정, 삭제 기능

- [ ] SetlistListView 구현
- [ ] SetlistRow 컴포넌트
- [ ] 검색/정렬 기능
- [ ] CreateSetlistView 구현
- [ ] SetlistDetailView 구현
- [ ] SetlistInfoSection 구현

**완료 조건**:
- ✅ 콘티 CRUD 기능 동작
- ✅ 콘티 정보 편집 가능
- ✅ UI 정상 작동

### Phase 5: 콘티-곡 연결 (2-3일)

**목표**: 콘티에 곡 추가, 순서 변경, 삭제

- [ ] SongPickerView 구현
- [ ] SetlistItemRow 구현
- [ ] 곡 정보 표시 및 커스텀 설정
- [ ] Drag & Drop 구현
- [ ] 순서 변경 저장
- [ ] 삭제 기능 (Swipe)

**완료 조건**:
- ✅ 콘티에 곡 추가 동작
- ✅ 순서 변경 동작
- ✅ 곡 삭제 동작
- ✅ 관계 데이터 정상 저장

### Phase 6: 개선 및 최적화 (1-2일)

**목표**: 사용자 경험 개선, 버그 수정

- [ ] 에러 Alert 추가
- [ ] 유효성 검사 메시지
- [ ] 로딩 인디케이터
- [ ] 애니메이션 추가
- [ ] 빈 상태 UI (ContentUnavailableView)
- [ ] 접근성 레이블
- [ ] 쿼리 최적화
- [ ] 이미지 캐싱
- [ ] 메모리 관리

**완료 조건**:
- ✅ 모든 에러 케이스 처리
- ✅ 부드러운 애니메이션
- ✅ 성능 테스트 통과

### Phase 7: 고급 기능 (선택사항, 향후 개발)

- [ ] 곡 내보내기/가져오기 (JSON, PDF)
- [ ] iCloud 동기화
- [ ] 콘티 공유 기능
- [ ] 다크 모드 최적화
- [ ] iPad 최적화 레이아웃
- [ ] Apple Watch 연동
- [ ] 메트로놈 기능
- [ ] 코드 차트 생성기

---

## 📁 프로젝트 파일 구조

```
Musicon/
├── MusiconApp.swift              # App entry point
├── Models/
│   ├── Song.swift                # Song model
│   ├── SongSection.swift         # Song section model
│   ├── Setlist.swift             # Setlist model
│   ├── SetlistItem.swift         # Setlist item model
│   └── Enums/
│       ├── SectionType.swift     # Section type enum
│       └── ValidationError.swift # Validation errors
├── Services/
│   ├── SongService.swift         # Song business logic
│   └── SetlistService.swift     # Setlist business logic
├── Views/
│   ├── RootView.swift           # Tab view
│   ├── Songs/
│   │   ├── SongListView.swift
│   │   ├── SongDetailView.swift
│   │   └── CreateSongView.swift
│   ├── Setlists/
│   │   ├── SetlistListView.swift
│   │   ├── SetlistDetailView.swift
│   │   └── CreateSetlistView.swift
│   └── Shared/
│       ├── SongPickerView.swift
│       └── ImageViewer.swift
├── Components/
│   ├── SongRow.swift
│   ├── SetlistRow.swift
│   ├── SetlistItemRow.swift
│   ├── SongInfoSection.swift
│   ├── SetlistInfoSection.swift
│   ├── SheetMusicSection.swift
│   ├── SongStructureSection.swift
│   └── ImagePicker.swift
└── Assets.xcassets/
```

---

## 🎯 개발 우선순위

1. **P0 (필수)**: Phase 1-5 → 핵심 기능
2. **P1 (중요)**: Phase 6 → 안정성 및 UX
3. **P2 (선택)**: Phase 7 → 고급 기능

**예상 개발 기간**: 10-15일 (Phase 1-6)

---

## 🚀 시작하기

### 요구사항

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### 설치

```bash
# Clone the repository
git clone <repository-url>

# Open in Xcode
open Musicon.xcodeproj
```

### 빌드 및 실행

1. Xcode에서 프로젝트 열기
2. 시뮬레이터 또는 실제 기기 선택
3. `Cmd + R` 로 빌드 및 실행

---

## 📝 개발 노트

### 데이터 검증 규칙

- **곡 제목**: 필수, 빈 문자열 불가
- **템포**: 1-300 BPM 범위
- **카포**: 0-12 범위
- **악보 이미지**: 최대 10장 제한
- **콘티 제목**: 필수, 빈 문자열 불가
- **콘티 순서**: 중복 불가

### 이미지 저장 전략

- JPEG 압축률: 0.8
- SwiftData `@Attribute(.externalStorage)` 사용
- 최대 10장 제한으로 스토리지 관리

### 쿼리 최적화

- 자주 검색되는 필드에 `@Attribute(.indexed)` 적용
- 곡 제목, 생성/수정 날짜 인덱싱
- 콘티 제목, 공연 날짜 인덱싱

---

## 🤝 기여

이 프로젝트는 개인 학습 프로젝트입니다.

---

## 📄 라이선스

[MIT License](LICENSE)

---

## 📧 연락처

프로젝트 관련 문의: [이메일 주소]

---

**Last Updated**: 2025-10-12
