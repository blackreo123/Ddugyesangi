import SwiftUI
import GoogleMobileAds

// MARK: - 싱글톤 배너 광고 관리자
class BannerAdManager: ObservableObject {
    static let shared = BannerAdManager()
    
    private var bannerView: GADBannerView?
    private var isLoaded = false
    
    private init() {}
    
    func getBannerView() -> GADBannerView {
        if bannerView == nil {
            createBannerView()
        }
        return bannerView!
    }
    
    private func createBannerView() {
        let newBannerView = GADBannerView(adSize: GADAdSizeBanner)
        
#if DEBUG
        newBannerView.adUnitID = Constants.AdIDs.bannerTest
#else
        newBannerView.adUnitID = Constants.AdIDs.banner
#endif
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            newBannerView.rootViewController = rootViewController
        }
        
        // ✅ SDK 초기화 완료 후에만 로드
        if !isLoaded && AdService.shared.isAdLoaded {
            let request = GADRequest()
            newBannerView.load(request)
            isLoaded = true
            print("🟢 배너 광고 로드됨 (한 번만)")
        } else if !AdService.shared.isAdLoaded {
            print("⏳ 배너 광고 대기 중 - SDK 초기화 완료 대기")
        }
        
        self.bannerView = newBannerView
    }
    
    func refreshAd() {
        // 필요시에만 광고 새로고침 (예: 5분마다)
        guard let banner = bannerView else { return }
        let request = GADRequest()
        banner.load(request)
        print("🟡 배너 광고 새로고침됨")
    }
    
    // ✅ SDK 초기화 완료 후 광고 로드
    func loadAdIfReady() {
        guard let banner = bannerView, !isLoaded, AdService.shared.isAdLoaded else { return }
        
        let request = GADRequest()
        banner.load(request)
        isLoaded = true
        print("🟢 배너 광고 로드됨 (한 번만)")
    }
}

// MARK: - 개선된 BannerAdView
struct BannerAdView: UIViewRepresentable {
    @StateObject private var adManager = BannerAdManager.shared
    
    func makeUIView(context: Context) -> GADBannerView {
        return adManager.getBannerView()
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 불필요한 업데이트 방지
    }
} 
