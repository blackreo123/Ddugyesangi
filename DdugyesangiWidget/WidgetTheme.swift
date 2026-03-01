//
//  WidgetTheme.swift
//  DdugyesangiWidget
//
//  위젯에서 사용하는 테마 색상 정의 (메인 앱의 AppTheme과 동일한 색상값)
//

import SwiftUI

enum WidgetThemeType: String, CaseIterable {
    case basic
    case lightPurple
    case red
    case blue
    case pink
    case spring
    case summer
    case autumn
    case winter
}

struct WidgetTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color

    static let themes: [WidgetThemeType: WidgetTheme] = [
        .basic: WidgetTheme(
            primaryColor: .blue,
            secondaryColor: .gray,
            backgroundColor: .white,
            textColor: .black
        ),
        .lightPurple: WidgetTheme(
            primaryColor: Color(red: 0.69, green: 0.32, blue: 0.87),
            secondaryColor: Color(red: 0.90, green: 0.80, blue: 0.95),
            backgroundColor: Color(red: 0.99, green: 0.98, blue: 1.0),
            textColor: .black
        ),
        .red: WidgetTheme(
            primaryColor: .red,
            secondaryColor: Color(red: 1.0, green: 0.75, blue: 0.80),
            backgroundColor: Color(red: 1.0, green: 0.98, blue: 0.98),
            textColor: .black
        ),
        .blue: WidgetTheme(
            primaryColor: .blue,
            secondaryColor: Color(red: 0.75, green: 0.90, blue: 1.0),
            backgroundColor: Color(red: 0.98, green: 0.99, blue: 1.0),
            textColor: .black
        ),
        .pink: WidgetTheme(
            primaryColor: Color(red: 1.0, green: 0.41, blue: 0.71),
            secondaryColor: Color(red: 1.0, green: 0.85, blue: 0.93),
            backgroundColor: Color(red: 1.0, green: 0.99, blue: 0.99),
            textColor: .black
        ),
        .spring: WidgetTheme(
            primaryColor: Color(red: 0.85, green: 0.44, blue: 0.58),
            secondaryColor: Color(red: 0.95, green: 0.76, blue: 0.83),
            backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.97),
            textColor: Color(red: 0.35, green: 0.20, blue: 0.25)
        ),
        .summer: WidgetTheme(
            primaryColor: Color(red: 0.15, green: 0.55, blue: 0.50),
            secondaryColor: Color(red: 0.70, green: 0.80, blue: 0.75),
            backgroundColor: Color(red: 0.94, green: 0.98, blue: 0.97),
            textColor: Color(red: 0.12, green: 0.25, blue: 0.28)
        ),
        .autumn: WidgetTheme(
            primaryColor: Color(red: 0.80, green: 0.45, blue: 0.20),
            secondaryColor: Color(red: 0.90, green: 0.72, blue: 0.50),
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.93),
            textColor: Color(red: 0.35, green: 0.22, blue: 0.10)
        ),
        .winter: WidgetTheme(
            primaryColor: Color(red: 0.40, green: 0.55, blue: 0.75),
            secondaryColor: Color(red: 0.72, green: 0.82, blue: 0.92),
            backgroundColor: Color(red: 0.95, green: 0.97, blue: 1.0),
            textColor: Color(red: 0.20, green: 0.25, blue: 0.35)
        ),
    ]
}
