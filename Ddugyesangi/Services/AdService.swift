// AdService.swift - 정식 광고 서비스

import Foundation
import GoogleMobileAds

class AdService: NSObject, ObservableObject, GADBannerViewDelegate, GADFullScreenContentDelegate {
    static let shared = AdService()
    @Published var isBannerAdLoaded = false
    @Published var isRewardedAdLoaded = false
    @Published var isShowingRewardedAd = false
    @Published var adError: String?
    
    private var bannerView: GADBannerView?
    private var rewardedAd: GADRewardedAd?
    
    override init() {
        super.init()
        
        // 이전 정책 관련 데이터 정리
        cleanupOldPolicy()
        
        setupBannerAd()
        loadRewardedAd()
    }
    
    // MARK: - 이전 정책 데이터 정리
    
    private func cleanupOldPolicy() {
        // 한 번만 실행되도록
        if !UserDefaults.standard.bool(forKey: "policy_cleaned_up") {
            UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
            UserDefaults.standard.removeObject(forKey: "policy_migrated_to_7days")
            UserDefaults.standard.set(true, forKey: "policy_cleaned_up")
            UserDefaults.standard.synchronize()
            print("🧹 이전 정책 데이터 정리 완료")
        }
    }
    
    // MARK: - Rewarded Ad
    
    func loadRewardedAd() {
        #if DEBUG
        let adUnitID = Constants.AdIDs.rewardedTest
        print("🧪 테스트 보상형 광고 로드 (DEBUG)")
        #else
        let adUnitID = Constants.AdIDs.rewarded
        print("💰 실제 보상형 광고 로드")
        #endif
        
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isRewardedAdLoaded = false
                    self?.adError = error.localizedDescription
                    print("❌ 보상형 광고 로드 실패: \(error.localizedDescription)")
                    return
                }
                
                self?.rewardedAd = ad
                self?.isRewardedAdLoaded = true
                self?.adError = nil
                ad?.fullScreenContentDelegate = self
                print("✅ 보상형 광고 로드 성공")
            }
        }
    }
    
    // MARK: - Banner Ad
    
    private func setupBannerAd() {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        
        #if DEBUG
        let adUnitID = Constants.AdIDs.bannerTest
        print("🧪 테스트 배너 설정 (DEBUG)")
        #else
        let adUnitID = Constants.AdIDs.banner
        print("💰 실제 배너 설정")
        #endif
        
        bannerView.adUnitID = adUnitID
        bannerView.delegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        self.bannerView = bannerView
    }
    
    func loadBannerAd() {
        guard let bannerView = bannerView else {
            setupBannerAd()
            return
        }
        
        let request = GADRequest()
        bannerView.load(request)
    }
    
    // MARK: - 개발/테스트용
    
    #if DEBUG
    func getDebugInfo() -> String {
        return """
        🔧 AdService 디버그 정보
        - 배너 로드 상태: \(isBannerAdLoaded ? "✅" : "❌")
        - 보상형 로드 상태: \(isRewardedAdLoaded ? "✅" : "❌")
        - 광고 표시 중: \(isShowingRewardedAd ? "예" : "아니오")
        - 에러: \(adError ?? "없음")
        """
    }
    #endif
    
    // MARK: - 광고 표시
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        guard let ad = rewardedAd else {
            print("❌ 광고 준비 안됨")
            completion(false, 0)
            return
        }
        
        print("🎬 광고 표시")
        isShowingRewardedAd = true
        
        ad.present(fromRootViewController: viewController) { [weak self] in
            let reward = ad.adReward
            let rewardAmount = reward.amount.intValue
            
            DispatchQueue.main.async {
                self?.isShowingRewardedAd = false
                print("✅ 보상 지급: \(rewardAmount)")
                completion(true, rewardAmount)
                
                self?.loadRewardedAd()
            }
        }
    }
    
    func getBannerView() -> GADBannerView? {
        return bannerView
    }
    
    // MARK: - GADBannerViewDelegate
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = true
            self.adError = nil
            
            if bannerView.adUnitID == Constants.AdIDs.banner {
                print("✅ 실제 배너 광고 성공")
            } else {
                print("✅ 테스트 배너 광고 성공")
            }
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = false
            self.adError = error.localizedDescription
            print("❌ 배너 광고 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("👁️ 광고 노출")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
        }
        loadRewardedAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎬 광고 표시 시작")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
        }
        loadRewardedAd()
    }
}
