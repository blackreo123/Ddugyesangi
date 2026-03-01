# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ddugyesangi (뜨개질) is a knitting counter iOS app built with SwiftUI. It helps users track row counts (단수) and stitch counts (코수) across multiple knitting projects and parts. The app includes AI-powered knitting pattern analysis via the Claude API.

- **Bundle ID**: `com.jihayoon.ddugyesangi`
- **Minimum iOS**: 17.6
- **Swift**: 5.0
- **Language**: Korean (primary), with English and Japanese localization

## Build & Run

This is a standard Xcode project (no workspace/CocoaPods). Open `Ddugyesangi.xcodeproj` in Xcode.

```bash
# Build from command line
xcodebuild -project Ddugyesangi.xcodeproj -scheme Ddugyesangi -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project Ddugyesangi.xcodeproj -scheme Ddugyesangi -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Dependencies are managed via Swift Package Manager (resolved automatically by Xcode):
- **Google Mobile Ads SDK** — banner and rewarded ads
- **Alamofire** — HTTP networking (used by ClaudeAPIService)
- **Firebase iOS SDK** — FirebaseAnalytics, FirebaseAuth, FirebaseFirestore (usage tracking for AI analysis)

## Architecture

**MVVM pattern** with a singleton `CoreDataManager`.

### Data Flow
```
Views → ViewModels → CoreDataManager.shared → Core Data (NSPersistentContainer)
```

- **ViewModels** (`ProjectListViewModel`, `PartListViewModel`, `PartDetailViewModel`) are `ObservableObject` classes that own `@Published` state and delegate persistence to `CoreDataManager.shared`.
- **Core Data entities**: `Project` (has many `Part`), `Part` (belongs to `Project`). The data model file is `Ddugyesangi.xcdatamodeld` with a v2 migration.
- **ThemeManager** is injected as `@EnvironmentObject` from the app root. Theme selection is persisted in `UserDefaults`.

### Key Singletons
| Singleton | Purpose |
|---|---|
| `CoreDataManager.shared` | All Core Data CRUD operations |
| `AdService.shared` | Google AdMob banner & rewarded ads |
| `AIAnalysisManager.shared` | AI pattern analysis orchestration, credit management |

### AI Analysis Flow
`SmartAddView` → `AIAnalysisManager` → `ClaudeAPIService` (via Alamofire) → Claude API. The Claude API key is loaded from `Config.plist` (not committed). Usage is tracked via `FirebaseUsageTracker` with a monthly free credit system and ad-reward credits.

### Services
- **AdService** — Manages banner/rewarded ads. Uses test ad IDs in `DEBUG` builds, production IDs in release.
- **LifecycleManager** — Handles app lifecycle events and ATT (App Tracking Transparency) permission requests.
- **ClaudeAPIService** — Sends PDF/image files to Claude API for knitting pattern analysis. Auto-selects best available model.

## Localization

Three languages: Korean (`ko`), English (`en`), Japanese (`ja`). Localized strings are in `{lang}.lproj/Localizable.strings` and `{lang}.lproj/InfoPlist.strings`. Use `NSLocalizedString()` for all user-facing strings.

## Configuration

- **Config.plist** — Contains `CLAUDE_API_KEY` (not in git). Required for AI analysis features.
- **GoogleService-Info.plist** — Firebase configuration.
- **Constants.swift** — AdMob IDs, app version, Claude API settings.
- Ad unit IDs switch between test/production based on `#if DEBUG`.

## Git 규칙

- 커밋 메시지에 `Co-Authored-By` 등 AI 관련 태그를 남기지 않는다.
- 문서, 코드, 커밋 등 어떤 산출물에도 AI가 작성했음을 표시하지 않는다.

## Changelog

완료된 작업은 [CHANGELOG.md](CHANGELOG.md)에 기록.

## TODO (개선 아이디어)

우선순위 순으로 정리. 모두 구현 예정은 아니며 기록용.

1. **WidgetKit 위젯** — 홈/잠금화면에서 현재 단수 확인 및 +1 가능
2. **카운터 UX 개선** — 터치 영역 확대(화면 전체 탭), Haptic 피드백, Undo(실행 취소), 화면 꺼짐 방지
3. **NavigationStack 마이그레이션** — deprecated NavigationView 전환 (코드 내 TODO 있음)
4. **코수 목표 설정 + 메모** — 코수 진행률 표시 (현재 targetValue: 0 하드코딩), 파트별 메모 기능
5. **iCloud 동기화** — NSPersistentCloudKitContainer로 기기 간 데이터 동기화
