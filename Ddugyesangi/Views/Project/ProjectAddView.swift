//
//  ProjectAddView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/26.
//

import Foundation
import SwiftUI

struct ProjectAddView: View {
    let viewModel: ProjectListViewModel
    @Binding var isPresented: Bool
    @State private var projectName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("뜨개질 이름", text: $projectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("새 뜨개질")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.createProject(name: projectName.trimmingCharacters(in: .whitespacesAndNewlines))
                            isPresented = false
                        }
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
