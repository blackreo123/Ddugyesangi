import Foundation

// 앱에서 사용할 기본 데이터 모델들
struct AppData {
    // 여기에 앱에서 사용할 데이터 구조들을 정의
}

// 광고 관련 데이터 모델
struct AdData {
    let adUnitID: String
    let adType: AdType
}

enum AdType {
    case banner
    case interstitial
    case rewarded
}

// 뜨개질 기록을 위한 뷰 모델
struct KnittingRecordViewModel: Identifiable {
    let id: UUID
    let name: String
    let patternName: String
    let castOnStitches: Int
    let totalRows: Int
    let currentRow: Int
    let createdAt: Date
    let updatedAt: Date
    
    init(from record: KnittingRecord) {
        self.id = record.id ?? UUID()
        self.name = record.name ?? ""
        self.patternName = record.patternName ?? ""
        self.castOnStitches = Int(record.castOnStitches)
        self.totalRows = Int(record.totalRows)
        self.currentRow = Int(record.currentRow)
        self.createdAt = record.createdAt ?? Date()
        self.updatedAt = record.updatedAt ?? Date()
    }
}

// 뜨개질 패턴을 위한 뷰 모델
struct KnittingPatternViewModel: Identifiable {
    let id: UUID
    let name: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(from pattern: KnittingPattern) {
        self.id = pattern.id ?? UUID()
        self.name = pattern.name ?? ""
        self.notes = pattern.notes
        self.createdAt = pattern.createdAt ?? Date()
        self.updatedAt = pattern.updatedAt ?? Date()
    }
} 