//
//  CircularProgressView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/16.
//

import Foundation
import SwiftUI

struct CircularProgressView: View {
    let currentValue: Int16
    let targetValue: Int16
    
    var body: some View {
        VStack {
            ProgressView(value: Float(currentValue / targetValue))
                .progressViewStyle(.circular)
        }
    }
}
