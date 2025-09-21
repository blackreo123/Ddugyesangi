import SwiftUI
import GoogleMobileAds

// MARK: - 간단한 배너 광고 뷰 (각 화면에서 AdService 인스턴스 생성해서 사용)
struct BannerAdView: UIViewRepresentable {
    let adService: AdService
    
    func makeUIView(context: Context) -> GADBannerView {
        guard let bannerView = adService.getBannerView() else {
            return GADBannerView() // 빈 뷰 반환
        }
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 필요시에만 업데이트
    }
}