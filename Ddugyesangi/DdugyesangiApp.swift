import SwiftUI
import GoogleMobileAds

@main
struct DdugyesangiApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var lifecycleManager = LifecycleManager()
    
    init() {
        // 앱 시작 시 Google Mobile Ads 초기화
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // AdService 초기화
        _ = AdService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(lifecycleManager)
                .tint(themeManager.currentTheme.primaryColor)
        }
    }
} 
