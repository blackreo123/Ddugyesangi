//
//  PartDetailView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

struct PartDetailView: View {
    let part: Part
    let viewModel: PartDetailViewModel = PartDetailViewModel()
    
    public var body: some View {
        HStack(spacing: 40) {
            VStack(spacing: 20) {
                Counter(part: part, viewModel: viewModel, type: .row)
                Text("시작 단수: \(part.startRow)")
            }
            VStack(spacing: 20) {
                Counter(part: part, viewModel: viewModel, type: .stitch)
                Text("시작 코수: \(part.startStitch)")
            }
        }
        .navigationTitle(part.name ?? "")
    }
}
