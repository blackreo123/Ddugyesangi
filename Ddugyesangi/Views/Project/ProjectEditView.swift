//
//  ProjectEditView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/26.
//

import Foundation
import SwiftUI

// 프로젝트 편집 뷰
struct ProjectEditView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let project: Project
    let viewModel: ProjectListViewModel
    @Binding var isPresented: Bool
    @State private var projectName: String
    
    init(project: Project, viewModel: ProjectListViewModel, isPresented: Binding<Bool>) {
        self.project = project
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._projectName = State(initialValue: project.name ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    NomalTextField(placeholder: NSLocalizedString("Project Name", comment: ""), text: $projectName)
                    Spacer()
                }
                .navigationTitle("Edit Project")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let isNameValid = !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button("Save") {
                            if isNameValid {
                                viewModel.updateProject(project, newName: projectName.trimmingCharacters(in: .whitespacesAndNewlines))
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
