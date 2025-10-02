//
//  Counter.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

enum CounterType {
    case row
    case stitch
}

struct Counter: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentValue: Int?
    let part: Part
    let viewModel: PartDetailViewModel
    let type: CounterType
    @State var count = 0
    @State private var inputText = ""
    @State private var isEditing: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingStitchResetAlert = false
    
    init(part: Part, viewModel: PartDetailViewModel, type: CounterType) {
        let current = Self.extractCurrentValue(from: part, type: type)
        self.part = part
        self.currentValue = current
        self.viewModel = viewModel
        self.type = type
        
        if let currentValue = current {
            self._count = State(initialValue: currentValue)
        } else {
            self._count = State(initialValue: 0)
        }
    }
    
    private static func extractCurrentValue(from part: Part, type: CounterType) -> Int? {
        switch type {
        case .row:
            return Int(part.currentRow)
        case .stitch:
            return Int(part.currentStitch)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            switch type {
            case .row:
                ProgressBarView(currentValue: $count, targetValue: Int(part.targetRow))
            case .stitch:
                 ProgressBarView(currentValue: $count, targetValue: 0)
            }

            // 위쪽 화살표 버튼
            Button(action: {
                count += 1
                if type == .row {
                    viewModel.incrementCurrentRow(part: part)
                } else if type == .stitch {
                    viewModel.incrementCurrentStitch(part: part)
                }
            }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
            
            if isEditing {
                TextField("\(count)", text: $inputText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                    .multilineTextAlignment(.center)
                    .frame(width: 120, height: 100)
                    .background(themeManager.currentTheme.cardColor)
                    .cornerRadius(15)
                    .focused($isTextFieldFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                commitEdit()
                            }
                        }
                    }
            } else {
                Text("\(count)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 100)
                    .background(themeManager.currentTheme.primaryColor)
                    .cornerRadius(15)
                    .onTapGesture {
                        startEditing()
                    }
            }
            
            // 아래쪽 화살표 버튼
            Button(action: {
                if count > 0 {
                    count -= 1
                    if type == .row {
                        viewModel.decrementCurrentRow(part: part)
                    } else if type == .stitch {
                        viewModel.decrementCurrentStitch(part: part)
                    }
                }
            }) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(count > 0 ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.secondaryColor)
            }
            .disabled(count <= 0)
            
            switch type {
            case .row:
                Text("").frame(height: 44)
            case .stitch:
                if part.isSmart {
                    // AI 분석 결과: 단수별 목표 코수 표시 (나중에 구현)
                    Text("AI Pattern Guide")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                } else {
                    // 일반 모드: 리셋 버튼
                    Button(action: {
                        showingStitchResetAlert = true
                    }) {
                        Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 24))
                            .foregroundStyle(count == 0 ? themeManager.currentTheme.secondaryColor : themeManager.currentTheme.primaryColor)
                            .frame(height: 44)
                    }
                    .disabled(count == 0)
                }
            }
        }
        .alert("Reset Stitch Count", isPresented: $showingStitchResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                count = 0
                viewModel.resetCurrentStitch(part: part)
            }
        } message: {
            Text("Are you sure you want to reset the stitch count to 0?")
        }
    }
    
    // 편집 시작
    private func startEditing() {
        inputText = String(count)
        isEditing = true
        isTextFieldFocused = true
    }
    
    // 편집 완료
    private func commitEdit() {
        switch type {
        case .row:
            if let newValue = Int(inputText), newValue > 0, newValue <= part.targetRow {
                count = newValue
                viewModel.updateCurrentRow(part: part, to: Int16(newValue))
            }
        case .stitch:
            if let newValue = Int(inputText), newValue > 0 {
                count = newValue
                viewModel.updateCurrentStitch(part: part, to: Int16(newValue))
            }
        }
        isEditing = false
        isTextFieldFocused = false
    }
}
