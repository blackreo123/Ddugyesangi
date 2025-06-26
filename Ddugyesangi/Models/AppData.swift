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
