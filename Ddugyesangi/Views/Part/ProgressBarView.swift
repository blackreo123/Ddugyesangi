//
//  ProgressBarView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/16.
//

import Foundation
import SwiftUI

struct ProgressBarView: View {
    @Binding var currentValue: Int
    let targetValue: Int
    
    private var progressValue: Double {
        guard targetValue > 0 else { return 0.0 }
        let progress = Double(currentValue) / Double(targetValue)
        return min(max(progress, 0.0), 1.0)
    }
    
    var body: some View {
        VStack {
            ProgressView(value: progressValue) { 
                Text("\(currentValue) / \(targetValue)") 
            }
        }
        .progressViewStyle(LinearProgressViewStyle())
        .padding(4)
        .cornerRadius(4)
    }
}
