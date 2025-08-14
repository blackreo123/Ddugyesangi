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
    let minValue: Int
    let currentValue: Int?
    let part: Part
    let viewModel: PartDetailViewModel
    let type: CounterType
    @State var count = 0
    @State private var inputText = ""
    
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
            return (Int(part.currentStitch), Int(part.startStitch))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
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
                    .foregroundColor(.blue)
            }
            
            // 카운터 숫자 (탭하면 직접 입력)
            Button(action: {
                inputText = String(count)
            }) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 80)
                    .overlay(
                        Text("\(count)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    )
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
                    .foregroundColor(count > minValue ? .blue : .gray)
            }
            .disabled(count <= minValue)
        }
    }
}
