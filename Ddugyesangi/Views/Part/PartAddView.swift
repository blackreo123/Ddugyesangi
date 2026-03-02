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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var name = ""
    @State private var targetRow = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NomalTextField(placeholder: NSLocalizedString("Part Name", comment: ""), text: $name)

                NomalTextField(placeholder: NSLocalizedString("Target row", comment: ""), text: $targetRow)
                    .keyboardType(.numberPad)

                // 메모 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("memo", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.textColor)
                        .padding(.horizontal, 16)

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
                            let memoText = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo.trimmingCharacters(in: .whitespacesAndNewlines)
                            viewModel.createPart(name: name, targetRow: targetRow ?? 0, memo: memoText, project: project)
                            isPresented = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
