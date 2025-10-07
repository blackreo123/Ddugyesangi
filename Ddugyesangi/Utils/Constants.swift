import Foundation

struct Constants {
    // 광고 ID들
    struct AdIDs {
        static let bannerTest = "ca-app-pub-3940256099942544/2934735716"
        static let banner = "ca-app-pub-7521928283190614/6447748065"
        
        static let rewardedTest = "ca-app-pub-3940256099942544/1712485313"
        static let rewarded = "ca-app-pub-7521928283190614/9344225989"
    }
    
    // 앱 설정
    struct App {
        static let name = "Ddugyesangi"
        static let version = "1.5.0"
    }
    
    struct Claude {
        static let apiKey: String = {
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let apiKey = plist["CLAUDE_API_KEY"] as? String else {
                return ""
            }
            return apiKey
        }()
        
        // Claude API 설정
        static let anthropicVersion = "2023-06-01"
        static let baseURL = "https://api.anthropic.com/v1"
        
        // 모델 캐시 설정 (1시간)
        static let modelCacheExpiration: TimeInterval = 3600
    }
}
