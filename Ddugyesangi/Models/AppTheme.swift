//
//  AppTheme.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/18.
//

import Foundation
import SwiftUI

enum ThemeType: String, CaseIterable {
    case basic
    case lightPurple
    case red
    case blue
    case pink
    
    var localizedName: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

struct AppTheme {
    let type: ThemeType
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let cardColor: Color
    let textColor: Color
    let accentColor: Color
    
    static let themes: [ThemeType: AppTheme] = [
        .basic: AppTheme(
            type: .basic,
            primaryColor: .blue,
            secondaryColor: .gray,
            backgroundColor: .white,
            cardColor: Color(red: 0.95, green: 0.95, blue: 0.97),
            textColor: .black,
            accentColor: .blue
        ),
        .lightPurple: AppTheme(
            type: .lightPurple,
            primaryColor: Color(red: 0.69, green: 0.32, blue: 0.87),
            secondaryColor: Color(red: 0.90, green: 0.80, blue: 0.95),
            backgroundColor: Color(red: 0.99, green: 0.98, blue: 1.0),
            cardColor: Color(red: 0.96, green: 0.92, blue: 0.99),
            textColor: .black,
            accentColor: .purple
        ),
        .red: AppTheme(
            type: .red,
            primaryColor: .red,
            secondaryColor: Color(red: 1.0, green: 0.75, blue: 0.80),
            backgroundColor: Color(red: 1.0, green: 0.98, blue: 0.98),
            cardColor: Color(red: 1.0, green: 0.94, blue: 0.94),
            textColor: .black,
            accentColor: .red
        ),
        .blue: AppTheme(
            type: .blue,
            primaryColor: .blue,
            secondaryColor: Color(red: 0.75, green: 0.90, blue: 1.0),
            backgroundColor: Color(red: 0.98, green: 0.99, blue: 1.0),
            cardColor: Color(red: 0.93, green: 0.96, blue: 1.0),
            textColor: .black,
            accentColor: .blue
        ),
        .pink: AppTheme(
            type: .pink,
            primaryColor: Color(red: 1.0, green: 0.41, blue: 0.71),    // 선명한 핑크
            secondaryColor: Color(red: 1.0, green: 0.85, blue: 0.93),  // 연한 핑크
            backgroundColor: Color(red: 1.0, green: 0.99, blue: 0.99), // 아주 연한 핑크 배경
            cardColor: Color(red: 1.0, green: 0.96, blue: 0.98),       // 카드용 연한 핑크
            textColor: .black,
            accentColor: Color(red: 1.0, green: 0.41, blue: 0.71)      // 액센트도 메인 핑크
        )
    ]
}
