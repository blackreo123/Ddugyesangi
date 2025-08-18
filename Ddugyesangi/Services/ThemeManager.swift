//
//  ThemeManager.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/18.
//

import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    
    init() {
        // UserDefaults에서 저장된 테마 불러오기
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeType.basic.rawValue
        let themeType = ThemeType(rawValue: savedTheme) ?? .basic
        self.currentTheme = AppTheme.themes[themeType] ?? AppTheme.themes[.basic]!
    }
    
    func changeTheme(to themeType: ThemeType) {
        currentTheme = AppTheme.themes[themeType] ?? AppTheme.themes[.basic]!
        UserDefaults.standard.set(themeType.rawValue, forKey: "selectedTheme")
    }
}
