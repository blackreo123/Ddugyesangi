//
//  ProgressBarView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/16.
//

import Foundation
import SwiftUI

struct ProgressBarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var currentValue: Int
    let targetValue: Int

    private var progressValue: Double {
        guard targetValue > 0 else { return 0.0 }
        let progress = Double(currentValue) / Double(targetValue)
        return min(max(progress, 0.0), 1.0)
    }

    private var barGradient: LinearGradient {
        let theme = themeManager.currentTheme
        let colors: [Color]
        switch theme.type {
        case .spring:
            colors = [
                Color(red: 0.95, green: 0.60, blue: 0.70),
                Color(red: 0.85, green: 0.44, blue: 0.58),
                Color(red: 0.75, green: 0.35, blue: 0.50)
            ]
        case .summer:
            colors = [
                Color(red: 0.40, green: 0.80, blue: 0.75),
                Color(red: 0.25, green: 0.70, blue: 0.65),
                Color(red: 0.55, green: 0.85, blue: 0.55)
            ]
        case .autumn:
            colors = [
                Color(red: 0.90, green: 0.55, blue: 0.25),
                Color(red: 0.80, green: 0.45, blue: 0.20),
                Color(red: 0.70, green: 0.35, blue: 0.15)
            ]
        case .winter:
            colors = [
                Color(red: 0.45, green: 0.60, blue: 0.85),
                Color(red: 0.35, green: 0.50, blue: 0.75),
                Color(red: 0.28, green: 0.42, blue: 0.68)
            ]
        default:
            colors = [
                theme.primaryColor.opacity(0.5),
                theme.primaryColor,
                theme.accentColor
            ]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentTheme.secondaryColor.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barGradient)
                        .frame(width: geometry.size.width * progressValue)
                        .animation(.easeInOut(duration: 0.3), value: progressValue)
                }
            }
            .frame(height: 8)

            Text("\(currentValue) / \(targetValue)")
                .contentTransition(.numericText())
        }
        .padding(4)
    }
}
