//
//  PartEditView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/15.
//

import Foundation
import SwiftUI

struct PartEditView: View {
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
        self._startRow = .init(initialValue: String(part.startRow))
        self._targetRow = .init(initialValue: String(part.targetRow))
        self._startStitch = .init(initialValue: String(part.startStitch))
        self._targetStitch = .init(initialValue: String(part.targetStitch))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("파트 이름")
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    TextField("파트 이름", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading) {
                    Text("시작 단수")
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    TextField("시작 단수", text: $startRow)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading) {
                    Text("목표 단수")
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    TextField("목표 단수", text: $targetRow)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading) {
                    Text("시작 코수")
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    TextField("시작 코수", text: $startStitch)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading) {
                    Text("목표 코수")
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    TextField("목표 코수", text: $targetStitch)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("파트 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let startRow = Int16(startRow)
                            let targetRow = Int16(targetRow)
                            let startStitch = Int16(startStitch)
                            let targetStitch = Int16(targetStitch)
                            viewModel.updatePart(part: part ,name: name, startRow: startRow ?? 0, targetRow: targetRow ?? 0, startStitch: startStitch ?? 0, targetStitch: targetStitch ?? 0)
                            isPresented = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
