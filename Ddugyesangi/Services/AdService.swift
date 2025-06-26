import Foundation
import GoogleMobileAds

class AdService: ObservableObject {
    static let shared = AdService()
    
    @Published var isAdLoaded = false
    @Published var adError: String?
    
    private init() {
        setupAds()
    }
    
    private func setupAds() {
        // Google Mobile Ads 초기화
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    func loadBannerAd() {
        // 배너 광고 로드 로직
        isAdLoaded = true
    }
    
    func showInterstitialAd() {
        // 전면 광고 표시 로직
    }
    
    func showRewardedAd() {
        // 보상형 광고 표시 로직
    }
} 