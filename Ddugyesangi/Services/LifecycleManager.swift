import SwiftUI
import Combine
import AppTrackingTransparency

class LifecycleManager: ObservableObject {
    @Published var appState: AppState = .background
    private var cancellables = Set<AnyCancellable>()
    private var hasRequestedATT = false
    private var lastAdRetryTime: Date?
    
    enum AppState {
        case background
        case foreground
    }
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // 앱이 활성화될 때
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.appDidBecomeActive()
            }
            .store(in: &cancellables)
        
        // 앱이 백그라운드로 갈 때
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.appWillResignActive()
            }
            .store(in: &cancellables)
        
        // 앱이 포그라운드로 돌아올 때
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.appWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    private func appDidBecomeActive() {
        appState = .foreground
        
        // 첫 번째 활성화에서만 ATT 요청
        if !hasRequestedATT {
            print("🚀 앱 첫 실행 - ATT 권한 요청 예정")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.requestATTPermissionIfNeeded()
                self.hasRequestedATT = true
            }
        }
        
        // 실제 광고 재시도 (5분마다)
        retryRealAdsIfNeeded()
    }
    
    private func appWillResignActive() {
        appState = .background
    }
    
    private func appWillEnterForeground() {
        print("📱 앱이 포그라운드로 돌아옴")
        
        // 백그라운드에서 돌아올 때도 광고 재시도
        retryRealAdsIfNeeded()
    }
    
    // MARK: - 광고 재시도 로직
    private func retryRealAdsIfNeeded() {
        // 마지막 재시도로부터 5분이 지났는지 확인
        let minimumInterval: TimeInterval = 300 // 5분
        
        if let lastRetry = lastAdRetryTime {
            let timeSinceLastRetry = Date().timeIntervalSince(lastRetry)
            guard timeSinceLastRetry >= minimumInterval else {
                print("⏱️ 광고 재시도 대기 중... (\(Int(minimumInterval - timeSinceLastRetry))초 후 재시도)")
                return
            }
        }
        
        // AdService가 테스트 모드일 때만 재시도
        if AdService.shared.isInTestMode {
            print("🔄 실제 광고로 재시도 시도...")
            AdService.shared.retryRealAds()
            lastAdRetryTime = Date()
        } else {
            print("✅ 이미 실제 광고 사용 중")
        }
    }
    
    // MARK: - 수동 광고 재시도
    func manualRetryRealAds() {
        print("👆 수동으로 실제 광고 재시도 요청")
        lastAdRetryTime = nil // 즉시 재시도 허용
        retryRealAdsIfNeeded()
    }
    
    private func requestATTPermissionIfNeeded() {
        // iOS 14 이상에서만 ATT 권한 요청
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("✅ ATT 권한이 허용되었습니다 - Google Ads SDK가 자동으로 개인화된 광고를 제공합니다")
                        // 권한 허용 시 즉시 실제 광고 재시도
                        AdService.shared.retryRealAds()
                    case .denied:
                        print("❌ ATT 권한이 거부되었습니다 - Google Ads SDK가 자동으로 비개인화된 광고를 제공합니다")
                    case .restricted:
                        print("⚠️ ATT 권한이 제한되었습니다 - Google Ads SDK가 자동으로 비개인화된 광고를 제공합니다")
                    case .notDetermined:
                        print("❓ ATT 권한 상태가 결정되지 않았습니다")
                    @unknown default:
                        print("🔄 알 수 없는 ATT 권한 상태입니다")
                    }
                }
            }
        } else {
            print("📱 iOS 14 미만 버전 - ATT 권한 요청 불필요, Google Ads SDK가 자동으로 개인화된 광고를 제공합니다")
        }
    }
}
