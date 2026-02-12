import Foundation
import SwiftUI

struct ThemeSelector: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                ThemedBackgroundView().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // 기본 테마 섹션
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("basic_themes", comment: ""))
                                .font(.headline)
                                .foregroundStyle(themeManager.currentTheme.textColor)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ThemeType.basicCases, id: \.self) { themeType in
                                    basicThemeButton(for: themeType)
                                }
                            }
                        }

                        // 계절 테마 섹션
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("seasonal_themes", comment: ""))
                                .font(.headline)
                                .foregroundStyle(themeManager.currentTheme.textColor)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ThemeType.seasonalCases, id: \.self) { themeType in
                                    seasonalThemeButton(for: themeType)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }

    private func basicThemeButton(for themeType: ThemeType) -> some View {
        Button {
            themeManager.changeTheme(to: themeType)
        } label: {
            Text(themeType.localizedName)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .foregroundColor(.white)
                .background(AppTheme.themes[themeType]?.primaryColor ?? .gray)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            themeManager.currentTheme.type == themeType ? Color.black : Color.clear,
                            lineWidth: 3
                        )
                )
        }
    }

    private func seasonalThemeButton(for themeType: ThemeType) -> some View {
        let theme = AppTheme.themes[themeType]
        return Button {
            themeManager.changeTheme(to: themeType)
        } label: {
            ZStack {
                if let colors = theme?.gradientColors {
                    LinearGradient(
                        colors: colors,
                        startPoint: theme?.gradientStartPoint ?? .top,
                        endPoint: theme?.gradientEndPoint ?? .bottom
                    )
                }
                Text(themeType.localizedName)
                    .foregroundColor(theme?.textColor ?? .black)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        themeManager.currentTheme.type == themeType ? Color.black : Color.clear,
                        lineWidth: 3
                    )
            )
        }
    }
}
