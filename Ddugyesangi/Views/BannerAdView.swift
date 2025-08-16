import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        // 테스트 광고 ID
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // 본방
        bannerView.adUnitID = "ca-app-pub-7521928283190614/6447748065"
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 업데이트 로직이 필요한 경우 여기에 작성
    }
} 
