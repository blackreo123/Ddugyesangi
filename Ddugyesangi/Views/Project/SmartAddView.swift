//
//  SmartAddView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/04.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct SmartAddView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var aiManager = AIAnalysisManager.shared
    @Binding var isPresented: Bool
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String = ""
    @State private var showingFilePicker = false
    @State private var showingAnalysisResult = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                mainContentView
            }
            .navigationTitle("스마트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView(
                selectedFileData: $selectedFileData,
                selectedFileName: $selectedFileName,
                isPresented: $showingFilePicker
            )
        }
        .sheet(isPresented: $showingAnalysisResult) {
            if let result = aiManager.analysisResult {
                AnalysisResultView(
                    isPresented: $showingAnalysisResult,
                    analysisResult: result,
                    originalFileName: selectedFileName
                )
            }
        }
        .alert("분석 실패", isPresented: $showingErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: aiManager.analysisResult) { _, newResult in
            if newResult != nil {
                showingAnalysisResult = true
            }
        }
        .onChange(of: aiManager.errorMessage) { _, newError in
            if let error = newError, !error.isEmpty {
                errorMessage = error
                showingErrorAlert = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("dismissSmartAddView"))) { _ in
            isPresented = false
        }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        VStack(spacing: 20) {
            fileUploadSection
            fileReselectionButton
            Spacer()
            analysisSection
        }
    }
    
    private var fileUploadSection: some View {
        VStack(spacing: 16) {
            if !selectedFileName.isEmpty {
                selectedFileInfoView
            } else {
                fileSelectionButton
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var selectedFileInfoView: some View {
        VStack(spacing: 12) {
            Image(systemName: getFileIcon(for: selectedFileName))
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.primaryColor)
            
            fileInfoTextView
        }
        .padding()
        .background(selectedFileCardBackground)
    }
    
    private var fileInfoTextView: some View {
        VStack(spacing: 4) {
            Text("선택된 파일:")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(selectedFileName)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let fileData = selectedFileData {
                Text("크기: \(formatFileSize(fileData.count))")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
            }
        }
    }
    
    private var selectedFileCardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(themeManager.currentTheme.cardColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.primaryColor, lineWidth: 2)
            )
    }
    
    private var fileSelectionButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingFilePicker = true
            }) {
                fileSelectionButtonContent
            }
            .buttonStyle(PlainButtonStyle())
            
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                    Text("사진에서 선택")
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(themeManager.currentTheme.cardColor))
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                if let photo = newPhoto {
                    Task {
                        if let data = try? await photo.loadTransferable(type: Data.self) {
                            selectedFileData = data
                            selectedFileName = "photo_selected.jpg"
                        }
                    }
                }
            }
        }
    }
    
    private var fileSelectionButtonContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            fileSelectionTextView
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .background(fileSelectionButtonBackground)
    }
    
    private var fileSelectionTextView: some View {
        VStack(spacing: 8) {
            Text("도안 파일 또는 사진 선택")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("JPG, PNG, PDF, HEIC 파일\n(최대 20MB)")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var fileSelectionButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(themeManager.currentTheme.cardColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.primaryColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
    }
    
    @ViewBuilder
    private var fileReselectionButton: some View {
        if !selectedFileName.isEmpty {
            Button(action: {
                showingFilePicker = true
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("다른 파일 선택")
                }
                .foregroundColor(themeManager.currentTheme.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var analysisSection: some View {
        if !selectedFileName.isEmpty {
            VStack(spacing: 12) {
                creditInfoView
                analysisButton
            }
        }
    }
    
    @ViewBuilder
    private var creditInfoView: some View {
        if !aiManager.canUseAIAnalysis() {
            VStack(spacing: 8) {
                Text("AI 분석 크레딧이 부족합니다")
                    .font(.subheadline)
                    .foregroundColor(.red)
                
                Text("남은 크레딧: \(aiManager.remainingCredits)회")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                
                if aiManager.getRemainingAdRewards() > 0 {
                    Text("광고 시청으로 크레딧 획득 가능: \(aiManager.getRemainingAdRewards())회")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
            )
            .padding(.horizontal, 16)
        }
    }
    
    private var analysisButton: some View {
        Button(action: {
            analyzeDesign()
        }) {
            analysisButtonContent
        }
        .disabled(aiManager.isAnalyzing || !aiManager.canUseAIAnalysis())
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private var analysisButtonContent: some View {
        HStack {
            if aiManager.isAnalyzing {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Image(systemName: "wand.and.rays")
            }
            
            Text(aiManager.isAnalyzing ? "분석 중..." : "도안 분석 (\(aiManager.remainingCredits)회 남음)")
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(analysisButtonBackground)
    }
    
    private var analysisButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(aiManager.isAnalyzing || !aiManager.canUseAIAnalysis() ? 
                  themeManager.currentTheme.secondaryColor : themeManager.currentTheme.primaryColor)
    }
    
    // MARK: - Helper Methods
    
    private func analyzeDesign() {
        guard let selectedFileData = selectedFileData else { return }
        
        Task {
            // PDF 파일인 경우 전용 메서드 사용
            if selectedFileName.lowercased().hasSuffix(".pdf") {
                await aiManager.analyzePDFKnittingPattern(pdfData: selectedFileData, fileName: selectedFileName)
            } else {
                await aiManager.analyzeKnittingPatternFile(fileData: selectedFileData, fileName: selectedFileName)
            }
        }
    }
    
    private func getFileIcon(for fileName: String) -> String {
        let lowercasedFileName = fileName.lowercased()
        
        if lowercasedFileName.hasSuffix(".pdf") {
            return "doc.fill"
        } else if lowercasedFileName.hasSuffix(".jpg") || 
                  lowercasedFileName.hasSuffix(".jpeg") || 
                  lowercasedFileName.hasSuffix(".png") || 
                  lowercasedFileName.hasSuffix(".heic") || 
                  lowercasedFileName.hasSuffix(".heif") {
            return "photo.fill"
        } else {
            return "doc.fill"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    SmartAddView(isPresented: .constant(true))
        .environmentObject(ThemeManager())
}
