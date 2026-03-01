//
//  ThemeManager.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/18.
//

import Foundation
import SwiftUI
import WidgetKit

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme

    private static let sharedDefaults = UserDefaults(suiteName: CoreDataManager.appGroupIdentifier) ?? .standard

    init() {
        // UserDefaults에서 저장된 테마 불러오기
        let savedTheme = Self.sharedDefaults.string(forKey: "selectedTheme") ?? ThemeType.basic.rawValue
        let themeType = ThemeType(rawValue: savedTheme) ?? .basic
        self.currentTheme = AppTheme.themes[themeType] ?? AppTheme.themes[.basic]!
    }

    var isSeasonalTheme: Bool {
        currentTheme.type.isSeasonal
    }

    func changeTheme(to themeType: ThemeType) {
        currentTheme = AppTheme.themes[themeType] ?? AppTheme.themes[.basic]!
        Self.sharedDefaults.set(themeType.rawValue, forKey: "selectedTheme")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
