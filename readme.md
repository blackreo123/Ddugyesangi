# 뜨개질 (Ddugyesangi) - Knitting Counter App

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-green.svg" alt="SwiftUI 5.0">
  <img src="https://img.shields.io/badge/Version-1.4-brightgreen.svg" alt="Version 1.4">
</p>

뜨개질하는 분들을 위한 직관적이고 편리한 카운터 앱입니다. 단수와 코수를 쉽게 추적하고 관리할 수 있습니다.

## 🎯 주요 기능

### ✨ 현재 기능 (v1.4)
- **프로젝트 관리**: 여러 뜨개질 프로젝트를 동시에 관리
- **파트별 카운터**: 각 프로젝트를 여러 파트로 나누어 관리
- **단수/코수 카운터**: 터치로 간편하게 증감 가능
- **진행률 표시**: 시각적 진행률 바로 현재 상태 확인
- **다양한 테마**: 5가지 컬러 테마 지원 (기본, 연보라, 빨강, 파랑, 핑크)
- **검색 기능**: 프로젝트명으로 빠른 검색
- **광고 지원**: Google AdMob을 통한 배너 광고
- **다국어 지원**: 한국어, 일본어 지원

### 🚀 개발 예정 기능
- [ ] AI 도안 분석 기능
- [ ] 스마트 등록 vs 일반 등록 구분
- [ ] 코수 카운터 리셋 기능
- [ ] 시작/목표 코수 필드 제거
- [ ] AI 분석 기반 자동 목표 설정
- [ ] CloudKit 동기화

## 🛠 기술 스택

- **언어**: Swift 5.9
- **프레임워크**: SwiftUI, Combine
- **데이터베이스**: Core Data + CloudKit
- **광고**: Google Mobile Ads SDK
- **아키텍처**: MVVM Pattern
- **의존성 관리**: Swift Package Manager

## 📱 앱 구조

```
Ddugyesangi/
├── App/
│   ├── DdugyesangiApp.swift      # 앱 진입점
│   └── ContentView.swift         # 루트 뷰
├── Models/
│   ├── AppData.swift            # 데이터 모델
│   ├── AppTheme.swift           # 테마 정의
│   └── ListViewType.swift       # 뷰 타입 enum
├── ViewModels/
│   ├── ProjectListViewModel.swift
│   ├── PartListViewModel.swift
│   ├── PartDetailViewModel.swift
│   └── ThemeManager.swift
├── Views/
│   ├── Project/
│   │   ├── ProjectListView.swift
│   │   ├── ProjectAddView.swift
│   │   └── ProjectEditView.swift
│   ├── Part/
│   │   ├── PartListView.swift
│   │   ├── PartDetailView.swift
│   │   ├── PartAddView.swift
│   │   └── PartEditView.swift
│   └── Components/
│       ├── Counter.swift
│       ├── ProgressBarView.swift
│       ├── ListRowView.swift
│       ├── NomalTextField.swift
│       ├── ThemeSelector.swift
│       ├── EmptyStateView.swift
│       └── BannerAdView.swift
├── Services/
│   ├── CoreDataManager.swift    # Core Data 관리
│   ├── AdService.swift          # 광고 서비스
│   └── Constants.swift          # 상수 정의
└── Resources/
    ├── Localizable.strings      # 다국어 리소스
    ├── Info.plist              # 앱 설정
    └── Launch Screen.storyboard # 런치 스크린
```

## 🏗 설치 및 실행

### 요구사항
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### 설정 단계

1. **저장소 클론**
```bash
git clone https://github.com/yourusername/Ddugyesangi.git
cd Ddugyesangi
```

2. **의존성 설치**
   - Xcode에서 프로젝트 열기
   - Package Dependencies에서 Google Mobile Ads SDK 자동 설치됨

3. **광고 ID 설정**
   - `Constants.swift`에서 실제 AdMob ID로 교체
   - `Info.plist`에서 GADApplicationIdentifier 업데이트

4. **빌드 및 실행**
   - Xcode에서 실행하거나 `Cmd + R`

## 🎨 앱 스크린샷

*스크린샷을 여기에 추가하세요*

## 📊 Core Data 스키마

### Project Entity
- `id: UUID` - 고유 식별자
- `name: String` - 프로젝트명
- `createdAt: Date` - 생성일
- `parts: [Part]` - 관련 파트들

### Part Entity
- `id: UUID` - 고유 식별자
- `name: String` - 파트명
- `startRow: Int16` - 시작 단수
- `targetRow: Int16` - 목표 단수
- `currentRow: Int16` - 현재 단수
- `targetStitch: Int16` - 목표 코수
- `currentStitch: Int16` - 현재 코수
- `createdAt: Date` - 생성일
- `project: Project` - 소속 프로젝트

## 🌈 테마 시스템

앱은 5가지 컬러 테마를 지원합니다(늘려갈 예정):
- **기본 (Basic)**: 클래식 블루
- **연보라 (Light Purple)**: 부드러운 퍼플
- **빨강 (Red)**: 생생한 레드
- **파랑 (Blue)**: 시원한 블루
- **핑크 (Pink)**: 따뜻한 핑크

각 테마는 Primary, Secondary, Background, Card, Text, Accent 색상을 정의합니다.

## 🔄 업데이트 내역

### v1.4 (현재)
- 기본 프로젝트/파트 관리 기능
- 단수/코수 카운터
- 테마 시스템
- 광고 시스템

### 다음 버전 계획
- AI 도안 분석 기능 추가
- 사용성 개선
- 추가 언어 지원

## 🤝 기여하기

1. Fork 프로젝트
2. 새 기능 브랜치 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경사항 커밋 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시 (`git push origin feature/AmazingFeature`)
5. Pull Request 생성

## 📝 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

프로젝트 관련 문의: [jihaapp1010@gmail.com]

프로젝트 링크: [https://github.com/blackreo123/Ddugyesangi](https://github.com/yourusername/Ddugyesangi)

## 🙏 감사의 말

- Google Mobile Ads SDK
- Apple CloudKit
- SwiftUI Community
- 모든 뜨개질 애호가들에게
