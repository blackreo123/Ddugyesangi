import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct SmartAddView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = SmartAddViewModel()
    @ObservedObject private var aiManager = AIAnalysisManager.shared
    @Binding var isPresented: Bool
    
    // 재선택용 PhotosPicker를 위한 별도 State
    @State private var reselectedPhoto: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            mainNavigationContent
        }
        .modifier(SheetsModifier(viewModel: viewModel))
        .modifier(AlertsModifier(viewModel: viewModel))
        .modifier(ListenersModifier(viewModel: viewModel, isPresented: $isPresented))
    }
    
    private var mainNavigationContent: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            mainContentView
        }
        .navigationTitle(NSLocalizedString("smart_add", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        VStack(spacing: 20) {
            fileUploadSection
            fileReselectionButtons
            Spacer()
            analysisSection
            noticeSection
        }
    }
    
    private var fileUploadSection: some View {
        VStack(spacing: 16) {
            if !viewModel.selectedFileName.isEmpty {
                selectedFileInfoView
            } else {
                fileSelectionButton
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var selectedFileInfoView: some View {
        VStack(spacing: 12) {
            filePreviewView
            fileInfoTextView
        }
        .padding()
        .background(selectedFileCardBackground)
    }
    
    @ViewBuilder
    private var filePreviewView: some View {
        if let fileData = viewModel.selectedFileData,
           let uiImage = UIImage(data: fileData) {
            // 이미지 미리보기
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 1)
                )
        } else {
            // 파일 아이콘 (이미지가 아닌 경우)
            Image(systemName: viewModel.getFileIcon(for: viewModel.selectedFileName))
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }
    
    private var fileInfoTextView: some View {
        VStack(spacing: 4) {
            Text(NSLocalizedString("selected_file", comment: ""))
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(viewModel.selectedFileName)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let fileData = viewModel.selectedFileData {
                Text(String(format: NSLocalizedString("file_size_format", comment: ""), viewModel.formatFileSize(fileData.count)))
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
            documentPickerButton
            photoPickerButton
        }
    }
    
    private var documentPickerButton: some View {
        Button(action: {
            viewModel.showingFilePicker = true
        }) {
            fileSelectionButtonContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(
            selection: $viewModel.selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                Text(NSLocalizedString("select_from_photos", comment: ""))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(themeManager.currentTheme.cardColor))
        }
        .onChange(of: viewModel.selectedPhoto) { _, newPhoto in
            handlePhotoSelection(newPhoto)
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
            Text(NSLocalizedString("select_pattern_or_photo", comment: ""))
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(NSLocalizedString("supported_file_formats", comment: ""))
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
    private var fileReselectionButtons: some View {
        if !viewModel.selectedFileName.isEmpty {
            HStack(spacing: 12) {
                // 다른 파일 선택 버튼
                Button(action: {
                    viewModel.showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(NSLocalizedString("select_different_file", comment: ""))
                    }
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                    )
                }
                
                // 다른 사진 선택 버튼 (별도 바인딩 사용)
                PhotosPicker(
                    selection: $reselectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo")
                        Text(NSLocalizedString("select_different_photo", comment: ""))
                    }
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.currentTheme.primaryColor, lineWidth: 1)
                    )
                }
                .onChange(of: reselectedPhoto) { _, newPhoto in
                    handlePhotoReselection(newPhoto)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var analysisSection: some View {
        if !viewModel.selectedFileName.isEmpty {
            VStack(spacing: 12) {
                creditInfoView
                analysisButton
            }
        }
    }
    
    @ViewBuilder
    private var creditInfoView: some View {
        if !aiManager.canUseAIAnalysis() {
            VStack(spacing: 12) {
                creditInfoText
                
                if viewModel.remainingAdRewards > 0 {
                    adRewardButton
                    
                    if !viewModel.adService.isRewardedAdLoaded {
                        loadingIndicator
                    }
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
    
    private var creditInfoText: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("insufficient_ai_credits", comment: ""))
                .font(.subheadline)
                .foregroundColor(.red)
            
            if viewModel.remainingAdRewards > 0 {
                Text(String(format: NSLocalizedString("ad_rewards_available", comment: ""), viewModel.remainingAdRewards))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
            }
        }
    }
    
    private var adRewardButton: some View {
        Button(action: {
            showRewardedAd()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                Text(NSLocalizedString("watch_ad_for_credits", comment: ""))
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(adRewardButtonBackground)
        }
        .disabled(!viewModel.adService.isRewardedAdLoaded || viewModel.adService.isShowingRewardedAd)
    }
    
    private var adRewardButtonBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(viewModel.adService.isRewardedAdLoaded ? Color.green : Color.gray)
    }
    
    private var loadingIndicator: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.8)
            Text(NSLocalizedString("loading_ad", comment: ""))
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
        }
    }
    
    private var analysisButton: some View {
        Button(action: {
            viewModel.analyzeDesign()
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
            
            Text(aiManager.isAnalyzing
                ? NSLocalizedString("analyzing", comment: "")
                : String(format: NSLocalizedString("analyze_pattern_credits", comment: ""),
                         aiManager.remainingCredits))
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(analysisButtonBackground)
    }
    
    private var analysisButtonBackground: some View {
        let isDisabled = aiManager.isAnalyzing || !aiManager.canUseAIAnalysis()
        return RoundedRectangle(cornerRadius: 12)
            .fill(isDisabled ? themeManager.currentTheme.secondaryColor : themeManager.currentTheme.primaryColor)
    }
    
    private var noticeSection: some View {
        VStack(spacing: 8) {
            noticeHeader
            noticeContent
        }
        .padding(12)
        .background(noticeBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private var noticeHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
            Text(NSLocalizedString("notice", comment: ""))
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(themeManager.currentTheme.secondaryColor)
    }
    
    private var noticeBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(themeManager.currentTheme.secondaryColor.opacity(0.1))
    }
    
    private var noticeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            noticeItem1
            noticeItem2
            noticeItem3
        }
        .font(.system(size: 12))
        .foregroundColor(themeManager.currentTheme.secondaryColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var noticeItem1: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(NSLocalizedString("ai_accuracy_notice", comment: ""))
        }
    }
    
    private var noticeItem2: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(NSLocalizedString("analysis_tip", comment: ""))
        }
    }
    
    private var noticeItem3: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("⚠️")
            Text(NSLocalizedString("credit_will_be_used", comment: ""))
                .fontWeight(.medium)
                .foregroundColor(Color.orange)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handlePhotoSelection(_ photo: PhotosPickerItem?) {
        if let photo = photo {
            Task {
                if let data = try? await photo.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        viewModel.selectedFileData = data
                        
                        // 파일명을 타임스탬프로 고유하게 생성
                        let timestamp = Date().timeIntervalSince1970
                        viewModel.selectedFileName = "photo_\(Int(timestamp)).jpg"
                        
                        // PhotosPicker 바인딩 초기화 (다음 선택을 위해)
                        viewModel.selectedPhoto = nil
                    }
                }
            }
        }
    }
    
    private func handlePhotoReselection(_ photo: PhotosPickerItem?) {
        if let photo = photo {
            Task {
                if let data = try? await photo.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        viewModel.selectedFileData = data
                        
                        // 파일명을 타임스탬프로 고유하게 생성
                        let timestamp = Date().timeIntervalSince1970
                        viewModel.selectedFileName = "photo_\(Int(timestamp)).jpg"
                        
                        // PhotosPicker 바인딩 초기화 (다음 선택을 위해)
                        reselectedPhoto = nil
                    }
                }
            }
        }
    }
    
    private func showRewardedAd() {
        guard let topViewController = getTopViewController() else {
            print("❌ 최상위 ViewController를 찾을 수 없음")
            viewModel.errorMessage = NSLocalizedString("cannot_display_ad", comment: "")
            viewModel.showingErrorAlert = true
            return
        }
        
        print("✅ 광고를 표시할 ViewController: \(type(of: topViewController))")
        viewModel.showRewardedAd(from: topViewController)
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = window.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}

// MARK: - View Modifiers

private struct SheetsModifier: ViewModifier {
    @ObservedObject var viewModel: SmartAddViewModel
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showingFilePicker) {
                FilePickerView(
                    selectedFileData: $viewModel.selectedFileData,
                    selectedFileName: $viewModel.selectedFileName,
                    isPresented: $viewModel.showingFilePicker
                )
            }
            .sheet(isPresented: $viewModel.showingAnalysisResult) {
                if let result = viewModel.aiManager.analysisResult {
                    AnalysisResultView(
                        isPresented: $viewModel.showingAnalysisResult,
                        analysisResult: result,
                        originalFileName: viewModel.selectedFileName
                    )
                }
            }
    }
}

private struct AlertsModifier: ViewModifier {
    @ObservedObject var viewModel: SmartAddViewModel
    
    func body(content: Content) -> some View {
        content
            .alert(NSLocalizedString("analysis_failed", comment: ""), isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert(NSLocalizedString("ad_watch_complete", comment: ""), isPresented: $viewModel.showingAdRewardAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(NSLocalizedString("credits_added", comment: ""))
            }
    }
}

private struct ListenersModifier: ViewModifier {
    @ObservedObject var viewModel: SmartAddViewModel
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.aiManager.analysisResult) { _, newResult in
                if newResult != nil {
                    viewModel.showingAnalysisResult = true
                }
            }
            .onChange(of: viewModel.aiManager.errorMessage) { _, newError in
                if let error = newError, !error.isEmpty {
                    viewModel.errorMessage = extractDisplayError(from: error)
                    viewModel.showingErrorAlert = true
                }
            }
            .onChange(of: viewModel.aiManager.remainingCredits) { _, _ in
                viewModel.loadAdRewards()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("dismissSmartAddView"))) { _ in
                isPresented = false
            }
            .task {
                viewModel.loadAdRewards()
            }
            .onAppear {
                viewModel.aiManager.resetAnalysisState()
            }
    }
    
    private func extractDisplayError(from errorMessage: String) -> String {
        if let separatorIndex = errorMessage.firstIndex(of: "#") {
            let displayPart = String(errorMessage[..<separatorIndex])
            return NSLocalizedString(displayPart, comment: "")
        }
        return NSLocalizedString(errorMessage, comment: "")
    }
}

#Preview {
    SmartAddView(isPresented: .constant(true))
        .environmentObject(ThemeManager())
}
