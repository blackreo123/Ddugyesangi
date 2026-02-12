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
    case spring
    case summer
    case autumn
    case winter

    var localizedName: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }

    var isSeasonal: Bool {
        switch self {
        case .spring, .summer, .autumn, .winter:
            return true
        default:
            return false
        }
    }

    static var basicCases: [ThemeType] {
        [.basic, .lightPurple, .red, .blue, .pink]
    }

    static var seasonalCases: [ThemeType] {
        [.spring, .summer, .autumn, .winter]
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
    let gradientColors: [Color]?
    let gradientStartPoint: UnitPoint?
    let gradientEndPoint: UnitPoint?

    init(type: ThemeType, primaryColor: Color, secondaryColor: Color, backgroundColor: Color, cardColor: Color, textColor: Color, accentColor: Color, gradientColors: [Color]? = nil, gradientStartPoint: UnitPoint? = nil, gradientEndPoint: UnitPoint? = nil) {
        self.type = type
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.cardColor = cardColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.gradientColors = gradientColors
        self.gradientStartPoint = gradientStartPoint
        self.gradientEndPoint = gradientEndPoint
    }

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
            primaryColor: Color(red: 1.0, green: 0.41, blue: 0.71),
            secondaryColor: Color(red: 1.0, green: 0.85, blue: 0.93),
            backgroundColor: Color(red: 1.0, green: 0.99, blue: 0.99),
            cardColor: Color(red: 1.0, green: 0.96, blue: 0.98),
            textColor: .black,
            accentColor: Color(red: 1.0, green: 0.41, blue: 0.71)
        ),
        // 계절 테마
        .spring: AppTheme(
            type: .spring,
            primaryColor: Color(red: 0.85, green: 0.44, blue: 0.58),
            secondaryColor: Color(red: 0.95, green: 0.76, blue: 0.83),
            backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.97),
            cardColor: Color(red: 1.0, green: 0.94, blue: 0.96).opacity(0.85),
            textColor: Color(red: 0.35, green: 0.20, blue: 0.25),
            accentColor: Color(red: 0.85, green: 0.44, blue: 0.58),
            gradientColors: [
                Color(red: 1.0, green: 0.94, blue: 0.96),
                Color(red: 0.98, green: 0.88, blue: 0.93),
                Color(red: 0.96, green: 0.91, blue: 0.95)
            ],
            gradientStartPoint: .top,
            gradientEndPoint: .bottom
        ),
        .summer: AppTheme(
            type: .summer,
            primaryColor: Color(red: 0.15, green: 0.55, blue: 0.50),
            secondaryColor: Color(red: 0.70, green: 0.80, blue: 0.75),
            backgroundColor: Color(red: 0.94, green: 0.98, blue: 0.97),
            cardColor: Color(red: 0.92, green: 0.97, blue: 0.96).opacity(0.85),
            textColor: Color(red: 0.12, green: 0.25, blue: 0.28),
            accentColor: Color(red: 0.75, green: 0.68, blue: 0.28),
            gradientColors: [
                Color(red: 0.14, green: 0.22, blue: 0.30),
                Color(red: 0.10, green: 0.28, blue: 0.25),
                Color(red: 0.08, green: 0.18, blue: 0.22)
            ],
            gradientStartPoint: .top,
            gradientEndPoint: .bottom
        ),
        .autumn: AppTheme(
            type: .autumn,
            primaryColor: Color(red: 0.80, green: 0.45, blue: 0.20),
            secondaryColor: Color(red: 0.90, green: 0.72, blue: 0.50),
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.93),
            cardColor: Color(red: 1.0, green: 0.95, blue: 0.90).opacity(0.85),
            textColor: Color(red: 0.35, green: 0.22, blue: 0.10),
            accentColor: Color(red: 0.80, green: 0.45, blue: 0.20),
            gradientColors: [
                Color(red: 1.0, green: 0.96, blue: 0.92),
                Color(red: 0.98, green: 0.92, blue: 0.85),
                Color(red: 0.96, green: 0.90, blue: 0.82)
            ],
            gradientStartPoint: .top,
            gradientEndPoint: .bottom
        ),
        .winter: AppTheme(
            type: .winter,
            primaryColor: Color(red: 0.40, green: 0.55, blue: 0.75),
            secondaryColor: Color(red: 0.72, green: 0.82, blue: 0.92),
            backgroundColor: Color(red: 0.95, green: 0.97, blue: 1.0),
            cardColor: Color(red: 0.93, green: 0.96, blue: 1.0).opacity(0.85),
            textColor: Color(red: 0.20, green: 0.25, blue: 0.35),
            accentColor: Color(red: 0.40, green: 0.55, blue: 0.75),
            gradientColors: [
                Color(red: 0.92, green: 0.95, blue: 1.0),
                Color(red: 0.88, green: 0.92, blue: 0.98),
                Color(red: 0.85, green: 0.90, blue: 0.97)
            ],
            gradientStartPoint: .top,
            gradientEndPoint: .bottom
        )
    ]
}
