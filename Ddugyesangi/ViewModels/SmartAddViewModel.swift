import Foundation
import _PhotosUI_SwiftUI
import SwiftUI

@MainActor
class SmartAddViewModel: ObservableObject {
    @ObservedObject var adService = AdService.shared
    @ObservedObject var aiManager = AIAnalysisManager.shared
    
    @Published var selectedFileData: Data?
    @Published var selectedFileName: String = ""
    @Published var showingFilePicker = false
    @Published var showingAnalysisResult = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var remainingAdRewards: Int = 0
    @Published var showingAdRewardAlert = false
    
    init() {
        loadAdRewards()
    }
    
    func loadAdRewards() {
        Task {
            remainingAdRewards = await aiManager.getRemainingAdRewards()
        }
    }
    
    func showRewardedAd(from viewController: UIViewController) {
        adService.showRewardedAd(from: viewController) { [weak self] success, rewardAmount in
            guard let self = self else { return }
            
            if success {
                Task {
                    // ✅ await를 사용하여 크레딧 추가가 완료될 때까지 대기
                    await self.aiManager.addCreditsFromAd()
                    
                    // 에러 메시지 확인
                    if let error = self.aiManager.errorMessage, !error.isEmpty {
                        await MainActor.run {
                            self.errorMessage = error
                            self.showingErrorAlert = true
                        }
                    } else {
                        // ✅ Firebase 업데이트 완료 후 최신 크레딧 가져오기
                        await self.aiManager.refreshCredits()
                        
                        // 성공 시 알럿 표시
                        await MainActor.run {
                            self.showingAdRewardAlert = true
                        }
                    }
                    
                    // 남은 광고 시청 횟수 업데이트
                    self.loadAdRewards()
                }
            } else {
                self.errorMessage = "광고를 불러오는데 실패했습니다. 잠시 후 다시 시도해주세요."
                self.showingErrorAlert = true
            }
        }
    }
    
    func analyzeDesign() {
        guard let selectedFileData = selectedFileData else { return }
        
        Task {
            if selectedFileName.lowercased().hasSuffix(".pdf") {
                await aiManager.analyzePDFKnittingPattern(pdfData: selectedFileData, fileName: selectedFileName)
            } else {
                await aiManager.analyzeKnittingPatternFile(fileData: selectedFileData, fileName: selectedFileName)
            }
            
            loadAdRewards()
        }
    }
    
    func getFileIcon(for fileName: String) -> String {
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
    
    func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
