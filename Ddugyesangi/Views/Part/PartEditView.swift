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
    @State private var startStitch = ""
    @State private var targetRow = ""
    @State private var targetStitch = ""
    @State private var memo = ""

    init(part: Part, viewModel: PartListViewModel, isPresented: Binding<Bool>) {
        self.part = part
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._name = .init(initialValue: part.name ?? "")
        self._targetRow = .init(initialValue: String(part.targetRow))
        self._memo = .init(initialValue: part.memo ?? "")
    }

    var body: some View {
        NavigationStack {
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

                // 메모 편집
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("memo", comment: ""))
                        .foregroundStyle(themeManager.currentTheme.textColor)
                        .padding(.horizontal)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.cardColor)

                        if memo.isEmpty {
                            Text(NSLocalizedString("memo_placeholder", comment: ""))
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $memo)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(themeManager.currentTheme.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                    }
                    .frame(height: 100)
                    .padding(.horizontal, 16)
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
                            let targetRow = Int16(targetRow)
                            let memoText = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo.trimmingCharacters(in: .whitespacesAndNewlines)
                            viewModel.updatePart(part: part, name: name, targetRow: targetRow ?? 0, memo: memoText)
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
