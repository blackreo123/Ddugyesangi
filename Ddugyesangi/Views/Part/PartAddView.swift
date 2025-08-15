//
//  PartAddView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

struct PartAddView: View {
    let viewModel: PartListViewModel
    let project: Project
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var startRow = ""
    @State private var startStitch = ""
    @State private var targetRow = ""
    @State private var targetStitch = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("파트 이름", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("시작 단수", text: $startRow)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField("목표 단수", text: $targetRow)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField("시작 코수", text: $startStitch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField("목표 코수", text: $targetStitch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("새 파트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let startRow = Int16(startRow)
                            let targetRow = Int16(targetRow)
                            let startStitch = Int16(startStitch)
                            let targetStitch = Int16(targetStitch)
                            viewModel.createPart(name: name, startRow: startRow ?? 0, targetRow: targetRow ?? 0, startStitch: startStitch ?? 0, targetStitch: targetStitch ?? 0, project: project)
                            isPresented = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
