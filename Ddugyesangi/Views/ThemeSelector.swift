//
//  ThemeSelector.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/18.
//

import Foundation
import SwiftUI

struct ThemeSelector: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("테마 선택")
                        .font(.title)
                        .foregroundStyle(themeManager.currentTheme.textColor)
                    
                    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 10) {
                        ForEach(ThemeType.allCases, id: \.self) { themeType in
                            Button(themeType.rawValue) {
                                themeManager.changeTheme(to: themeType)
                            }
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .padding()
                            .background(AppTheme.themes[themeType]?.primaryColor ?? .gray)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        themeManager.currentTheme.type == themeType ? Color.black : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                        }
                    }
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
