import SwiftUI

@main
struct DdugyesangiApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .tint(themeManager.currentTheme.primaryColor)
        }
    }
} 
