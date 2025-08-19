//
//  NomalTextField.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/19.
//

import Foundation
import SwiftUI

struct NomalTextField: View {
    @EnvironmentObject var themeManager: ThemeManager
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
            HStack {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundStyle(themeManager.currentTheme.textColor)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }
}
