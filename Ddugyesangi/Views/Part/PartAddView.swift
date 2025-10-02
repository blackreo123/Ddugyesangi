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
    @State private var targetRow = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NomalTextField(placeholder: NSLocalizedString("Part Name", comment: ""), text: $name)
               
                NomalTextField(placeholder: NSLocalizedString("Target row", comment: ""), text: $targetRow)
                    .keyboardType(.numberPad)
                
                
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
                            let targetRow = Int16(targetRow)
                            viewModel.createPart(name: name, targetRow: targetRow ?? 0, project: project)
                            isPresented = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
