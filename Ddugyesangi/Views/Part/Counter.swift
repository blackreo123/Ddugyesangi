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
    let minValue: Int
    let currentValue: Int?
    let part: Part
    let viewModel: PartDetailViewModel
    let type: CounterType
    let isSmart: Bool = false
    @State var count = 0
    @State private var inputText = ""
    @State private var isEditing: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(part: Part, viewModel: PartDetailViewModel, type: CounterType) {
        let (current, min) = Self.extractValues(from: part, type: type)
        self.part = part
        self.currentValue = current
        self.minValue = min
        self.viewModel = viewModel
        self.type = type
        
        if let currentValue = currentValue {
            self._count = State(initialValue: currentValue)
        } else {
            self._count = State(initialValue: minValue)
        }
    }
    
    private static func extractValues(from part: Part, type: CounterType) -> (current: Int?, min: Int) {
        switch type {
        case .row:
            return (Int(part.currentRow), Int(part.startRow))
        case .stitch:
            return (Int(part.currentStitch), 0)
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
                if count > minValue {
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
                    .foregroundStyle(count > minValue ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.secondaryColor)
            }
            .disabled(count <= minValue)
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
        if let newValue = Int(inputText), newValue > minValue {
            count = newValue
        }
        isEditing = false
        isTextFieldFocused = false
    }
}
