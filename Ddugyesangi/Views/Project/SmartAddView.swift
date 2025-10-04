//
//  SmartAddView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/04.
//

import SwiftUI
import PhotosUI

struct SmartAddView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var aiManager = AIAnalysisManager.shared
    @Binding var isPresented: Bool
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingAnalysisResult = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 이미지 업로드 영역
                    VStack(spacing: 16) {
                        if let selectedImage = selectedImage {
                            // 선택된 이미지 표시
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.currentTheme.primaryColor, lineWidth: 2)
                                )
                        } else {
                            // 이미지 업로드 버튼 영역
                            VStack(spacing: 16) {
                                Button(action: {
                                    showingPhotoPicker = true
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                                        
                                        Text("사진 라이브러리에서 선택")
                                            .font(.headline)
                                            .foregroundColor(themeManager.currentTheme.textColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.currentTheme.cardColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.currentTheme.primaryColor, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 32))
                                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                                        
                                        Text("카메라로 촬영")
                                            .font(.headline)
                                            .foregroundColor(themeManager.currentTheme.textColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.currentTheme.cardColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.currentTheme.primaryColor, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("도안 분석을 위해 사진을 선택해 주세요.")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // 이미지가 선택되었을 때 재선택 버튼
                    if selectedImage != nil {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingPhotoPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("라이브러리")
                                }
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("카메라")
                                }
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                    
                    // 도안 분석 버튼
                    if selectedImage != nil {
                        VStack(spacing: 12) {
                            // 크레딧 정보 표시
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
                            
                            Button(action: {
                                analyzeDesign()
                            }) {
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
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(aiManager.isAnalyzing || !aiManager.canUseAIAnalysis() ? 
                                              themeManager.currentTheme.secondaryColor : themeManager.currentTheme.primaryColor)
                                )
                            }
                            .disabled(aiManager.isAnalyzing || !aiManager.canUseAIAnalysis())
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
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
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingAnalysisResult) {
            if let image = selectedImage, let result = aiManager.analysisResult {
                AnalysisResultView(
                    isPresented: $showingAnalysisResult,
                    analysisResult: result,
                    originalImage: image
                )
            }
        }
        .alert("분석 실패", isPresented: $showingErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
            }
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
    }
    
    private func analyzeDesign() {
        guard let selectedImage = selectedImage else { return }
        
        Task {
            await aiManager.analyzeKnittingPattern(image: selectedImage)
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    SmartAddView(isPresented: .constant(true))
        .environmentObject(ThemeManager())
}
