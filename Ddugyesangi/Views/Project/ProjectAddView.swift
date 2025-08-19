//
//  ProjectAddView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/26.
//

import Foundation
import SwiftUI

struct ProjectAddView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let viewModel: ProjectListViewModel
    @Binding var isPresented: Bool
    @State private var projectName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.cardColor)
                        HStack {
                            TextField("뜨개질 이름", text: $projectName)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    Spacer()
                }
                .navigationTitle("새 뜨개질")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") {
                            isPresented = false
                        }
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let isNameValid = !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button("저장") {
                            if isNameValid {
                                viewModel.createProject(name: projectName.trimmingCharacters(in: .whitespacesAndNewlines))
                                isPresented = false
                            }
                        }
                        .foregroundStyle(isNameValid ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.secondaryColor)
                        .disabled(!isNameValid)
                    }
                }
            }
        }
    }
}
