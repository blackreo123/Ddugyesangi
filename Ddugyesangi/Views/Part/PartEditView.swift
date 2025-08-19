//
//  PartEditView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/15.
//

import Foundation
import SwiftUI

struct PartEditView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let part: Part
    let viewModel: PartListViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var startRow = ""
    @State private var startStitch = ""
    @State private var targetRow = ""
    @State private var targetStitch = ""
    
    init(part: Part, viewModel: PartListViewModel, isPresented: Binding<Bool>) {
        self.part = part
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._name = .init(initialValue: part.name ?? "")
        self._startRow = .init(initialValue: String(part.startRow))
        self._targetRow = .init(initialValue: String(part.targetRow))
        self._startStitch = .init(initialValue: String(part.startStitch))
        self._targetStitch = .init(initialValue: String(part.targetStitch))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("파트 이름")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: "파트 이름", text: $name)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("시작 단수")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: "시작 단수", text: $startRow)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("목표 단수")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: "목표 단수", text: $targetRow)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("시작 코수")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: "시작 코수", text: $startStitch)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("목표 코수")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: "목표 코수", text: $targetStitch)
                            .keyboardType(.numberPad)
                    }
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("파트 편집")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button("저장") {
                            if isNameValid {
                                let startRow = Int16(startRow)
                                let targetRow = Int16(targetRow)
                                let startStitch = Int16(startStitch)
                                let targetStitch = Int16(targetStitch)
                                viewModel.updatePart(part: part ,name: name, startRow: startRow ?? 0, targetRow: targetRow ?? 0, startStitch: startStitch ?? 0, targetStitch: targetStitch ?? 0)
                                isPresented = false
                            }
                        }
                        .foregroundStyle(isNameValid ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.secondaryColor)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
