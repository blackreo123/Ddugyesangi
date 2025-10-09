// AdService.swift - 30일 대기 전략

import Foundation
import GoogleMobileAds

class AdService: NSObject, ObservableObject, GADBannerViewDelegate, GADFullScreenContentDelegate {
    static let shared = AdService()
    @Published var isBannerAdLoaded = false
    @Published var isRewardedAdLoaded = false
    @Published var isShowingRewardedAd = false
    @Published var adError: String?
    @Published var isUsingTestAds = false
    
    private var bannerView: GADBannerView?
    private var rewardedAd: GADRewardedAd?
    
    // 30일 대기 기간
    private let retryIntervalDays = 30
    
    override init() {
        super.init()
        
        // 광고 모드 결정
        determineAdMode()
        
        setupBannerAd()
        loadRewardedAd()
    }
    
    // MARK: - 광고 모드 결정 (핵심 로직)
    
    private func determineAdMode() {
        // 마지막 실패 날짜 확인
        if let lastFailureDate = UserDefaults.standard.object(forKey: "last_real_ad_failure") as? Date {
            let daysSinceFailure = Calendar.current.dateComponents([.day], from: lastFailureDate, to: Date()).day ?? 0
            
            print("📅 마지막 실제 광고 실패로부터 \(daysSinceFailure)일 경과")
            
            if daysSinceFailure < retryIntervalDays {
                // 30일 이내: 테스트 광고 사용
                isUsingTestAds = true
                let remainingDays = retryIntervalDays - daysSinceFailure
                print("🧪 테스트 광고 모드 (남은 기간: \(remainingDays)일)")
                
                // TODO: 제한 해제되면 이 부분 수정
                // UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
                // isUsingTestAds = false
                
            } else {
                // 30일 경과: 다시 실제 광고 시도
                isUsingTestAds = false
                print("🔄 30일 경과 - 실제 광고 재시도")
                
                // 재시도 표시 제거 (새로운 주기 시작)
                UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
            }
        } else {
            // 첫 실행 또는 기록 없음: 실제 광고 시도
            isUsingTestAds = false
            print("🚀 첫 실행 - 실제 광고 시도")
        }
    }
    
    // MARK: - Rewarded Ad
    
    func loadRewardedAd() {
        let adUnitID: String
        
        if isUsingTestAds {
            adUnitID = Constants.AdIDs.rewardedTest
            print("🧪 테스트 보상형 광고 로드")
        } else {
            #if DEBUG
            adUnitID = Constants.AdIDs.rewardedTest
            #else
            adUnitID = Constants.AdIDs.rewarded
            print("💰 실제 보상형 광고 시도")
            #endif
        }
        
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.handleRewardedAdFailure(error: error, adUnitID: adUnitID)
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.handleRewardedAdSuccess(ad: ad, adUnitID: adUnitID)
            }
        }
    }
    
    private func handleRewardedAdFailure(error: Error, adUnitID: String) {
        self.isRewardedAdLoaded = false
        self.adError = error.localizedDescription
        print("❌ 보상형 광고 로드 실패: \(error.localizedDescription)")
        
        // 실제 광고 실패 시
        if !isUsingTestAds && adUnitID == Constants.AdIDs.rewarded {
            print("📝 실제 광고 실패 - 30일 테스트 모드 시작")
            
            // 실패 날짜 기록
            UserDefaults.standard.set(Date(), forKey: "last_real_ad_failure")
            
            // 테스트 광고로 전환
            isUsingTestAds = true
            
            // 테스트 광고 로드
            loadTestRewardedAd()
            
            // 알림 (선택사항)
            logFailureInfo()
        } else if adUnitID == Constants.AdIDs.rewardedTest {
            // 테스트 광고도 실패 (네트워크 문제 등)
            print("❌ 테스트 광고도 실패 - 네트워크 확인 필요")
        }
    }
    
    private func handleRewardedAdSuccess(ad: GADRewardedAd?, adUnitID: String) {
        self.rewardedAd = ad
        self.isRewardedAdLoaded = true
        self.adError = nil
        ad?.fullScreenContentDelegate = self
        
        if adUnitID == Constants.AdIDs.rewarded {
            print("✅ 실제 광고 로드 성공! - AdMob 제한 해제됨")
            
            // 성공 시 기록 삭제
            UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
            UserDefaults.standard.set(Date(), forKey: "last_real_ad_success")
            
            isUsingTestAds = false
        } else {
            print("✅ 테스트 광고 로드 성공")
        }
    }
    
    private func loadTestRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: Constants.AdIDs.rewardedTest, request: request) { [weak self] ad, error in
            if error != nil {
                print("❌ 테스트 광고 로드 실패")
                self?.isRewardedAdLoaded = false
                return
            }
            
            DispatchQueue.main.async {
                self?.rewardedAd = ad
                self?.isRewardedAdLoaded = true
                ad?.fullScreenContentDelegate = self
                print("✅ 테스트 보상형 광고 로드 성공")
            }
        }
    }
    
    // MARK: - Banner Ad (동일한 로직)
    
    private func setupBannerAd() {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        
        let adUnitID: String
        if isUsingTestAds {
            adUnitID = Constants.AdIDs.bannerTest
            print("🧪 테스트 배너 설정")
        } else {
            #if DEBUG
            adUnitID = Constants.AdIDs.bannerTest
            #else
            adUnitID = Constants.AdIDs.banner
            print("💰 실제 배너 설정")
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
    }
    
    private func loadTestBannerAd() {
        guard let bannerView = bannerView else { return }
        
        bannerView.adUnitID = Constants.AdIDs.bannerTest
        let request = GADRequest()
        bannerView.load(request)
        print("🧪 테스트 배너 광고로 전환")
    }
    
    // MARK: - 유틸리티
    
    private func logFailureInfo() {
        print("""
        ⚠️ AdMob 제한 감지됨
        📅 현재 시각: \(Date())
        📅 다음 재시도: \(Date().addingTimeInterval(Double(retryIntervalDays) * 86400))
        💡 TODO: 제한 해제되면 다음 코드 실행
           - UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
           - isUsingTestAds = false
           - loadRewardedAd()
        """)
    }
    
    // 상태 확인 (디버그용)
    func getAdModeStatus() -> String {
        if isUsingTestAds {
            if let failureDate = UserDefaults.standard.object(forKey: "last_real_ad_failure") as? Date {
                let daysSince = Calendar.current.dateComponents([.day], from: failureDate, to: Date()).day ?? 0
                let remaining = max(0, retryIntervalDays - daysSince)
                return "테스트 광고 (남은 기간: \(remaining)일)"
            }
            return "테스트 광고"
        } else {
            return "실제 광고"
        }
    }
    
    // MARK: - 개발/테스트용 (선택사항)
    
    #if DEBUG
    // 개발 모드에서만 사용 가능한 수동 리셋
    func manualResetToRealAds() {
        print("🔧 [DEBUG] 수동으로 실제 광고로 리셋")
        UserDefaults.standard.removeObject(forKey: "last_real_ad_failure")
        isUsingTestAds = false
        
        setupBannerAd()
        loadBannerAd()
        loadRewardedAd()
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
            print("❌ 배너 광고 실패: \(error)")
            
            // 실제 광고 실패 시
            if !self.isUsingTestAds && bannerView.adUnitID == Constants.AdIDs.banner {
                // 보상형과 동일하게 30일 대기
                UserDefaults.standard.set(Date(), forKey: "last_real_ad_failure")
                self.isUsingTestAds = true
                self.loadTestBannerAd()
            }
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
