import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
#if DEBUG
        // 테스트 광고 ID
        bannerView.adUnitID = Constants.AdIDs.bannerTest
#else
        // 본방
        bannerView.adUnitID = Constants.AdIDs.banner
#endif
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 업데이트 로직이 필요한 경우 여기에 작성
    }
} 
