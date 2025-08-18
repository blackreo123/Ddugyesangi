//
//  AppTheme.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/18.
//

import Foundation
import SwiftUI

enum ThemeType: String, CaseIterable {
    case basic = "기본"
    case lightPurple = "연보라"
    case red = "빨강"
    case blue = "파랑"
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
            cardColor: Color.gray.opacity(0.1),
            textColor: .black,
            accentColor: .blue
        ),
        .lightPurple: AppTheme(
            type: .lightPurple,
            primaryColor: Color.purple.opacity(0.7),
            secondaryColor: Color.purple.opacity(0.3),
            backgroundColor: Color.purple.opacity(0.05),
            cardColor: Color.purple.opacity(0.08),
            textColor: .black,
            accentColor: .purple
        ),
        .red: AppTheme(
            type: .red,
            primaryColor: .red,
            secondaryColor: Color.pink.opacity(0.5),
            backgroundColor: Color.red.opacity(0.05),
            cardColor: Color.red.opacity(0.06),
            textColor: .black,
            accentColor: .red
        ),
        .blue: AppTheme(
            type: .blue,
            primaryColor: .blue,
            secondaryColor: Color.cyan.opacity(0.5),
            backgroundColor: Color.blue.opacity(0.05),
            cardColor: Color.blue.opacity(0.08),
            textColor: .black,
            accentColor: .blue
        )
    ]
}
