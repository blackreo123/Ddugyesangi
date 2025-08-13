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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
            }
            .padding(.top)
            .navigationTitle("새 파트 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
