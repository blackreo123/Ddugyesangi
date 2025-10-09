import SwiftUI
import Combine
import AppTrackingTransparency

class LifecycleManager: ObservableObject {
    @Published var appState: AppState = .background
    private var cancellables = Set<AnyCancellable>()
    private var hasRequestedATT = false
    
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
                self?.appState = .background
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
    }
    
    private func requestATTPermissionIfNeeded() {
        // iOS 14 이상에서만 ATT 권한 요청
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("✅ ATT 권한이 허용되었습니다 - Google Ads SDK가 자동으로 개인화된 광고를 제공합니다")
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
