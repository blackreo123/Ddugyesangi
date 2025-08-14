//
//  Counter.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

struct Counter: View {
    @State var count = 0
    @State private var inputText = ""
    @State private var minValue: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 위쪽 화살표 버튼
            Button(action: {
                count += 1
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
