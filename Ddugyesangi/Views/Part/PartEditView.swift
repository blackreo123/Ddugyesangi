//
//  PartEditView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/15.
//

import Foundation
import SwiftUI

struct PartEditView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let part: Part
    let viewModel: PartListViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var startRow = ""
    @State private var startStitch = ""
    @State private var targetRow = ""
    @State private var targetStitch = ""
    
    init(part: Part, viewModel: PartListViewModel, isPresented: Binding<Bool>) {
        self.part = part
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._name = .init(initialValue: part.name ?? "")
        self._targetRow = .init(initialValue: String(part.targetRow))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Part Name")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: NSLocalizedString("Part Name", comment: ""), text: $name)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Target row")
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        NomalTextField(placeholder: NSLocalizedString("Target row", comment: ""), text: $targetRow)
                            .keyboardType(.numberPad)
                    }
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("Edit Part")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button("Save") {
                            if isNameValid {
                                let startRow = Int16(startRow)
                                let targetRow = Int16(targetRow)
                                viewModel.updatePart(part: part ,name: name, targetRow: targetRow ?? 0)
                                isPresented = false
                            }
                        }
                        .foregroundStyle(isNameValid ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.secondaryColor)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
