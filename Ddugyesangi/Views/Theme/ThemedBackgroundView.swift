import SwiftUI

struct ThemedBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        if themeManager.isSeasonalTheme {
            SeasonalBackgroundView(theme: themeManager.currentTheme)
        } else {
            themeManager.currentTheme.backgroundColor
        }
    }
}

extension View {
    func themedBackground() -> some View {
        self.background {
            ThemedBackgroundView()
                .ignoresSafeArea()
        }
    }
}
