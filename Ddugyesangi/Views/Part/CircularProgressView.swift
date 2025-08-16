//
//  CircularProgressView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/16.
//

import Foundation
import SwiftUI

struct ProgressBarView: View {
    @Binding var currentValue: Int
    let targetValue: Int
    
    var body: some View {
        
        VStack {
            ProgressView(value: Double(currentValue) / Double(targetValue)) { Text("\(currentValue) / \(targetValue)") }
        }
        .progressViewStyle(LinearProgressViewStyle())
        .padding(4)
        .cornerRadius(4)
        
    }
}
