import SwiftUI
import GoogleMobileAds
import FirebaseCore

@main
struct DdugyesangiApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var lifecycleManager = LifecycleManager()
    @StateObject private var navigationRouter = NavigationRouter()

    init() {
        // 앱 시작 시 Google Mobile Ads 초기화만 진행
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        print("🚀 Google Mobile Ads SDK 초기화 완료")

        FirebaseApp.configure()
        print("✅ Firebase 초기화 완료")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(lifecycleManager)
                .environmentObject(navigationRouter)
                .tint(themeManager.currentTheme.primaryColor)
                .onOpenURL { url in
                    navigationRouter.handleDeepLink(url)
                }
        }
    }
}
