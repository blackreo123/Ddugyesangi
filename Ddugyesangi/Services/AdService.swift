import Foundation
import GoogleMobileAds

class AdService: NSObject, ObservableObject, GADBannerViewDelegate {
    @Published var isBannerAdLoaded = false
    @Published var adError: String?
    
    private var bannerView: GADBannerView?
    
    override init() {
        super.init()
        setupBannerAd()
    }
    
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
        print("🔄 배너 광고 로드 요청됨")
    }
    
    func getBannerView() -> GADBannerView? {
        return bannerView
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
}
