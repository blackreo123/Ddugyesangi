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
    @State private var targetRow = ""
    @State private var targetStitch = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField(NSLocalizedString("Part Name", comment: ""), text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField(NSLocalizedString("Start Row", comment: ""), text: $startRow)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField(NSLocalizedString("Target row", comment: ""), text: $targetRow)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField(NSLocalizedString("Start Stitch", comment: ""), text: $startStitch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                TextField(NSLocalizedString("Target Stitch", comment: ""), text: $targetStitch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Add New Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let startRow = Int16(startRow)
                            let targetRow = Int16(targetRow)
                            let startStitch = Int16(startStitch)
                            let targetStitch = Int16(targetStitch)
                            viewModel.createPart(name: name, startRow: startRow ?? 0, targetRow: targetRow ?? 0, startStitch: startStitch ?? 0, targetStitch: targetStitch ?? 0, project: project)
                            isPresented = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
