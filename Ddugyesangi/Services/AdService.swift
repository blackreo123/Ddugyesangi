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
        setupBannerAd()
        loadRewardedAd()
    }
    
    // MARK: - Banner Ad
    
    private func setupBannerAd() {
        print("🚀 AdService: 배너 광고 설정 시작")
        
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        
        #if DEBUG
        bannerView.adUnitID = Constants.AdIDs.bannerTest
        #else
        bannerView.adUnitID = Constants.AdIDs.banner
        #endif
        
        bannerView.delegate = self
        
        // rootViewController 설정
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        self.bannerView = bannerView
    }
    
    func loadBannerAd() {
        guard let bannerView = bannerView else { return }
        
        let request = GADRequest()
        bannerView.load(request)
        print("📄 배너 광고 로드 요청됨")
    }
    
    func getBannerView() -> GADBannerView? {
        return bannerView
    }
    
    // MARK: - Rewarded Ad
    
    func loadRewardedAd() {
        print("📄 보상형 광고 로드 시작")
        
        #if DEBUG
        let adUnitID = Constants.AdIDs.rewardedTest
        #else
        let adUnitID = Constants.AdIDs.rewarded
        #endif
        
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isRewardedAdLoaded = false
                    self?.adError = error.localizedDescription
                    print("❌ 보상형 광고 로드 실패: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.rewardedAd = ad
                self?.isRewardedAdLoaded = true
                self?.adError = nil
                // ✅ GADFullScreenContentDelegate 설정 (중요!)
                ad?.fullScreenContentDelegate = self
                print("✅ 보상형 광고 로드 성공")
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        guard let ad = rewardedAd else {
            print("❌ 보상형 광고가 준비되지 않음")
            completion(false, 0)
            return
        }
        
        print("🎬 보상형 광고 표시 시작")
        isShowingRewardedAd = true
        
        ad.present(fromRootViewController: viewController) { [weak self] in
            let reward = ad.adReward
            let rewardAmount = reward.amount.intValue
            
            DispatchQueue.main.async {
                self?.isShowingRewardedAd = false
                print("✅ 보상 지급: \(rewardAmount) \(reward.type)")
                completion(true, rewardAmount)
                
                // 다음 광고 미리 로드
                self?.loadRewardedAd()
            }
        }
    }
    
    // MARK: - GADBannerViewDelegate
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = true
            self.adError = nil
            print("✅ 배너 광고 로드 성공")
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = false
            self.adError = error.localizedDescription
            print("❌ 배너 광고 로드 실패: \(error.localizedDescription)")
        }
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("👁️ 배너 광고 노출됨")
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("📱 배너 광고 화면 표시됨")
    }
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("📱 배너 광고 화면 닫힘")
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    /// 광고가 성공적으로 표시되었을 때
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("👁️ 보상형 광고가 사용자에게 표시됨")
    }
    
    /// 광고 표시에 실패했을 때
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
            self.adError = error.localizedDescription
            print("❌ 보상형 광고 표시 실패: \(error.localizedDescription)")
        }
        
        // 실패 후 새 광고 로드
        loadRewardedAd()
    }
    
    /// 광고가 표시될 때
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎬 보상형 광고 화면이 곧 표시됨")
    }
    
    /// 광고가 닫힐 때
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("❌ 보상형 광고 화면이 닫힘")
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
        }
        
        // 광고가 닫힌 후 새 광고 로드
        loadRewardedAd()
    }
}
