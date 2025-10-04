//
//  AnalysisResultView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/04.
//

import SwiftUI

struct AnalysisResultView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var aiManager = AIAnalysisManager.shared
    @Binding var isPresented: Bool
    let analysisResult: KnittingAnalysis
    let originalImage: UIImage
    
    @State private var editedProjectName: String = ""
    @State private var editedParts: [EditableKnittingPart] = []
    @State private var showingCreateProject = false
    @State private var isCreatingProject = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 원본 이미지 표시
                        VStack(alignment: .leading, spacing: 12) {
                            Text("분석된 이미지")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Image(uiImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        
                        // 프로젝트 이름 편집
                        VStack(alignment: .leading, spacing: 12) {
                            Text("프로젝트 이름")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            TextField("프로젝트 이름을 입력하세요", text: $editedProjectName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        .padding(.horizontal, 16)
                        
                        // 분석된 파트들
                        VStack(alignment: .leading, spacing: 12) {
                            Text("분석된 파트 (\(editedParts.count)개)")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            ForEach(editedParts.indices, id: \.self) { index in
                                EditablePartView(
                                    part: $editedParts[index],
                                    onDelete: {
                                        editedParts.remove(at: index)
                                    }
                                )
                            }
                            
                            // 새 파트 추가 버튼
                            Button(action: addNewPart) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("새 파트 추가")
                                }
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("분석 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                    .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("프로젝트 생성") {
                        createProjectFromAnalysis()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .disabled(editedProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreatingProject)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 하단 프로젝트 생성 버튼
                Button(action: createProjectFromAnalysis) {
                    HStack {
                        if isCreatingProject {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.app")
                        }
                        
                        Text(isCreatingProject ? "프로젝트 생성 중..." : "프로젝트 생성")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(editedProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreatingProject ? 
                                  themeManager.currentTheme.secondaryColor : themeManager.currentTheme.primaryColor)
                    )
                }
                .disabled(editedProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreatingProject)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(themeManager.currentTheme.backgroundColor)
            }
        }
        .onAppear {
            setupInitialData()
        }
    }
    
    private func setupInitialData() {
        editedProjectName = analysisResult.projectName
        editedParts = analysisResult.parts.map { part in
            EditableKnittingPart(
                partName: part.partName,
                targetRow: part.targetRow,
                stitchGuide: part.stitchGuide.map { guide in
                    EditableStitchGuide(row: guide.row, targetStitch: guide.targetStitch)
                }
            )
        }
    }
    
    private func addNewPart() {
        let newPart = EditableKnittingPart(
            partName: "새 파트 \(editedParts.count + 1)",
            targetRow: 10,
            stitchGuide: []
        )
        editedParts.append(newPart)
    }
    
    private func createProjectFromAnalysis() {
        guard !editedProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreatingProject = true
        
        // EditableKnittingPart를 KnittingPart로 변환
        let knittingParts = editedParts.map { editablePart in
            KnittingPart(
                partName: editablePart.partName,
                targetRow: editablePart.targetRow,
                stitchGuide: editablePart.stitchGuide.map { editableGuide in
                    StitchGuide(row: editableGuide.row, targetStitch: editableGuide.targetStitch)
                }
            )
        }
        
        let finalAnalysis = KnittingAnalysis(
            projectName: editedProjectName.trimmingCharacters(in: .whitespacesAndNewlines),
            parts: knittingParts
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            _ = aiManager.createProjectFromAnalysis(finalAnalysis)
            isCreatingProject = false
            isPresented = false
        }
    }
}

// MARK: - Editable Data Models
struct EditableKnittingPart {
    var partName: String
    var targetRow: Int
    var stitchGuide: [EditableStitchGuide]
}

struct EditableStitchGuide {
    var row: Int
    var targetStitch: Int
}

// MARK: - Editable Part View
struct EditablePartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var part: EditableKnittingPart
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 파트 헤더
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                            .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.partName)
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text("목표: \(part.targetRow)단")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryColor)
                        }
                        
                        Spacer()
                    }
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
            )
            
            // 파트 상세 편집 (확장시)
            if isExpanded {
                VStack(spacing: 12) {
                    // 파트 이름 편집
                    HStack {
                        Text("파트 이름:")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        TextField("파트 이름", text: $part.partName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 목표 단 편집
                    HStack {
                        Text("목표 단:")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        TextField("목표 단", value: $part.targetRow, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // 스티치 가이드 개수 표시
                    if !part.stitchGuide.isEmpty {
                        Text("스티치 가이드: \(part.stitchGuide.count)개")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.currentTheme.cardColor.opacity(0.5))
                )
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
}

#Preview {
    AnalysisResultView(
        isPresented: .constant(true),
        analysisResult: KnittingAnalysis(
            projectName: "테스트 프로젝트",
            parts: [
                KnittingPart(
                    partName: "몸통",
                    targetRow: 50,
                    stitchGuide: [
                        StitchGuide(row: 10, targetStitch: 20),
                        StitchGuide(row: 25, targetStitch: 30)
                    ]
                )
            ]
        ),
        originalImage: UIImage(systemName: "photo") ?? UIImage()
    )
    .environmentObject(ThemeManager())
}
