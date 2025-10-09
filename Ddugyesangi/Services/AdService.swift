// AdService.swift - AdMob 정책 준수 버전

import Foundation
import GoogleMobileAds

class AdService: NSObject, ObservableObject, GADBannerViewDelegate, GADFullScreenContentDelegate {
    static let shared = AdService()
    @Published var isBannerAdLoaded = false
    @Published var isRewardedAdLoaded = false
    @Published var isShowingRewardedAd = false
    @Published var adError: String?
    @Published var isInTestMode = false
    
    private var bannerView: GADBannerView?
    private var rewardedAd: GADRewardedAd?
    private var lastAdShownTime: Date?
    
    override init() {
        super.init()
        checkAdMobStatus()
        setupBannerAd()
        loadRewardedAd()
    }
    
    // MARK: - AdMob 상태 체크
    private func checkAdMobStatus() {
        #if DEBUG
        isInTestMode = true
        print("⚠️ 개발 모드: 테스트 광고 사용")
        #else
        isInTestMode = UserDefaults.standard.bool(forKey: "force_test_ads")
        #endif
    }
    
    // MARK: - Rewarded Ad (정책 준수)
    func loadRewardedAd() {
        print("🔄 보상형 광고 로드 시작 (테스트 모드: \(isInTestMode))")
        
        let adUnitID: String
        if isInTestMode {
            adUnitID = Constants.AdIDs.rewardedTest
        } else {
            #if DEBUG
            adUnitID = Constants.AdIDs.rewardedTest
            #else
            adUnitID = Constants.AdIDs.rewarded
            #endif
        }
        
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isRewardedAdLoaded = false
                    self?.adError = error.localizedDescription
                    print("❌ 보상형 광고 로드 실패: \(error.localizedDescription)")
                    
                    // 실제 광고 실패 시 테스트 광고로 전환 (정책 준수)
                    if !(self?.isInTestMode ?? false) && adUnitID != Constants.AdIDs.rewardedTest {
                        print("🔄 테스트 광고로 재시도...")
                        self?.isInTestMode = true
                        UserDefaults.standard.set(true, forKey: "force_test_ads")
                        self?.loadRewardedAdWithTestID()
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.rewardedAd = ad
                self?.isRewardedAdLoaded = true
                self?.adError = nil
                ad?.fullScreenContentDelegate = self
                print("✅ 보상형 광고 로드 성공")
            }
        }
    }
    
    // 테스트 광고로 재시도
    private func loadRewardedAdWithTestID() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: Constants.AdIDs.rewardedTest, request: request) { [weak self] ad, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isRewardedAdLoaded = false
                    self?.adError = "광고를 로드할 수 없습니다: \(error.localizedDescription)"
                    print("❌ 테스트 광고도 실패: \(error)")
                    // 시뮬레이션 모드 없음 - 정책 준수
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.rewardedAd = ad
                self?.isRewardedAdLoaded = true
                self?.adError = nil
                ad?.fullScreenContentDelegate = self
                print("✅ 테스트 광고 로드 성공")
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        // 광고 빈도 제한 체크 (선택사항 - 사용자 경험 개선)
        if let lastTime = lastAdShownTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastTime)
            if timeSinceLastAd < 30 { // 30초 제한
                print("⏱️ 광고 표시 간격 제한 (30초)")
                completion(false, 0)
                return
            }
        }
        
        // 실제 광고가 없으면 보상 제공 안 함 (정책 준수)
        guard let ad = rewardedAd else {
            print("❌ 보상형 광고가 준비되지 않음")
            completion(false, 0)
            return
        }
        
        print("🎬 보상형 광고 표시 시작")
        isShowingRewardedAd = true
        lastAdShownTime = Date()
        
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
    
    // MARK: - Banner Ad (정책 준수)
    private func setupBannerAd() {
        print("🚀 배너 광고 설정 시작 (테스트 모드: \(isInTestMode))")
        
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        
        let adUnitID: String
        if isInTestMode {
            adUnitID = Constants.AdIDs.bannerTest
        } else {
            #if DEBUG
            adUnitID = Constants.AdIDs.bannerTest
            #else
            adUnitID = Constants.AdIDs.banner
            #endif
        }
        
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
        print("🔄 배너 광고 로드 요청됨")
    }
    
    // 테스트 배너 광고로 재시도
    private func loadBannerAdWithTestID() {
        print("🔄 배너: 테스트 광고로 재시도...")
        
        guard let bannerView = bannerView else { return }
        
        bannerView.adUnitID = Constants.AdIDs.bannerTest
        
        let request = GADRequest()
        bannerView.load(request)
    }
    
    func getBannerView() -> GADBannerView? {
        return bannerView
    }
    
    // MARK: - 테스트 모드 관리
    func toggleTestMode() {
        isInTestMode.toggle()
        UserDefaults.standard.set(isInTestMode, forKey: "force_test_ads")
        print("🔄 테스트 모드 변경: \(isInTestMode)")
        
        setupBannerAd()
        loadBannerAd()
        loadRewardedAd()
    }
    
    func retryRealAds() {
        guard isInTestMode else { return }
        
        print("🔄 실제 광고 재시도 시작...")
        isInTestMode = false
        UserDefaults.standard.set(false, forKey: "force_test_ads")
        
        setupBannerAd()
        loadBannerAd()
        loadRewardedAd()
    }
    
    // MARK: - GADBannerViewDelegate
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = true
            self.adError = nil
            
            if bannerView.adUnitID == Constants.AdIDs.bannerTest && !(self.isInTestMode) {
                print("✅ 배너 테스트 광고 로드 성공 → 다음번엔 실제 광고 시도")
                self.isInTestMode = false
                UserDefaults.standard.set(false, forKey: "force_test_ads")
            } else {
                print("✅ 배너 광고 로드 성공")
            }
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.isBannerAdLoaded = false
            self.adError = error.localizedDescription
            print("❌ 배너 광고 로드 실패: \(error.localizedDescription)")
            
            if !(self.isInTestMode) && bannerView.adUnitID != Constants.AdIDs.bannerTest {
                print("🔄 배너: 테스트 모드로 전환...")
                self.isInTestMode = true
                UserDefaults.standard.set(true, forKey: "force_test_ads")
                self.loadBannerAdWithTestID()
            }
        }
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("👁️ 배너 광고 노출됨")
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        print("👆 배너 광고 클릭됨 (자연스러운 사용자 행동)")
    }
    
    // MARK: - GADFullScreenContentDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("👁️ 보상형 광고 노출됨")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
            self.adError = error.localizedDescription
            print("❌ 보상형 광고 표시 실패: \(error.localizedDescription)")
        }
        
        loadRewardedAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎬 보상형 광고 화면 표시")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("❌ 보상형 광고 닫힘")
        DispatchQueue.main.async {
            self.isShowingRewardedAd = false
        }
        
        loadRewardedAd()
    }
}
