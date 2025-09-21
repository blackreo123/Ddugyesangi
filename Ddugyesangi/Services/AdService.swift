import Foundation
import Foundation
import GoogleMobileAds

class AdService: ObservableObject {
    static let shared = AdService()
    
    @Published var isAdLoaded = false
    @Published var adError: String?
    
    private var isSDKInitialized = false
    private let initializationQueue = DispatchQueue(label: "com.ddugyesangi.ad-init", qos: .userInitiated)
    
    private init() {
        setupAds()
    }
    
    private func setupAds() {
        print("🚀 AdService: 광고 서비스 초기화 시작")
        // LifecycleManager에서 이미 ATT를 처리하므로 바로 SDK 초기화
        initializeGoogleMobileAds()
    }
    
    private func initializeGoogleMobileAds() {
        let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, !self.isSDKInitialized else { return }
                
                print("🚀 Google Mobile Ads SDK 초기화 중...")
                
                GADMobileAds.sharedInstance().start { [weak self] status in
                    DispatchQueue.main.async {
                        self?.isSDKInitialized = true
                        self?.isAdLoaded = true
                        
                        print("✅ Google Mobile Ads SDK 초기화 완료")
                        print("📱 이제 광고가 시작됩니다")
                        
                        for (adapterClass, adapterStatus) in status.adapterStatusesByClassName {
                            let state = adapterStatus.state == .ready ? "준비됨 ✅" : "준비안됨 ❌"
                            print("  - \(adapterClass): \(state)")
                            
                            if adapterStatus.state != .ready {
                                print("     상태: \(adapterStatus.description)")
                            }
                        }
                    }
                }
            }
            initializationQueue.async(execute: workItem)
    }
    
    func loadBannerAd() {
        guard isSDKInitialized else {
            print("⚠️ AdService: SDK 초기화 대기 중...")
            adError = "SDK 초기화 중"
            return
        }
        
        // ✅ 중복 로드 방지 - BannerAdManager에서 처리
        // 필요시에만 새로고침 호출
        BannerAdManager.shared.refreshAd()
        isAdLoaded = true
        print("🔄 AdService: 배너 광고 새로고침 요청")
    }
    
    // MARK: - 전면 광고 및 보상 광고는 사용하지 않음
    
    func showInterstitialAd() {
        print("📺 AdService: 전면 광고는 사용하지 않습니다")
        // 전면 광고 사용하지 않음
    }
    
    func showRewardedAd() {
        print("🎁 AdService: 보상형 광고는 사용하지 않습니다")
        // 보상형 광고 사용하지 않음
    }
    
    // MARK: - Helper Methods
    
    /// 디버그 정보 출력
    func printDebugInfo() {
        print("🔍 AdService 디버그 정보:")
        print("   - SDK 초기화: \(isSDKInitialized ? "완료" : "대기중")")
        print("   - 광고 로드: \(isAdLoaded ? "완료" : "대기중")")
        if let error = adError {
            print("   - 오류: \(error)")
        }
        print("   - ATT는 LifecycleManager에서 관리됨")
    }
} 
