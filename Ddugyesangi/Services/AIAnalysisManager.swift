//
//  AIAnalysisManager.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/03.
//

import Foundation
import UIKit
import PDFKit

@MainActor
class AIAnalysisManager: ObservableObject {
    static let shared = AIAnalysisManager()
    
    @Published var remainingCredits: Int = 0
    @Published var lastResetDate: Date = Date()
    @Published var isAnalyzing: Bool = false
    @Published var analysisResult: KnittingAnalysis?
    @Published var errorMessage: String?
    @Published var isInitialized: Bool = false
    
    private let claudeService: ClaudeAPIService
    private let usageTracker = FirebaseUsageTracker()
    private let coreDataManager = CoreDataManager.shared
    
    // 사용량 제한 상수
    private let monthlyFreeLimit = 5
    private let adRewardAmount = 5
    private let maxAdRewards = 3
    
    // 실패 통계 추적
    private var consecutiveFailures = 0
    
    private init() {
        self.claudeService = ClaudeAPIService(apiKey: Constants.Claude.apiKey)
        
        // Firebase 초기화 및 사용량 로드
        Task {
            await initializeFirebase()
        }
    }
    
    // MARK: - Firebase 초기화
    
    private func initializeFirebase() async {
        do {
            print("🔥 Firebase 초기화 시작...")
            
            // Firebase 인증 초기화
            try await usageTracker.initialize()
            
            // 사용량 로드
            let credits = try await usageTracker.getRemainingCredits()
            
            remainingCredits = credits
            lastResetDate = Date()
            isInitialized = true
            print("✅ Firebase 초기화 완료: \(credits)회 남음")
            
        } catch {
            print("❌ Firebase 초기화 실패: \(error.localizedDescription)")
            
            // Fallback: 로컬 저장소 사용
            loadLocalCredits()
            isInitialized = true
            print("⚠️ 로컬 모드로 전환")
        }
    }
    
    // MARK: - 크레딧 관리
    
    /// Fallback: 로컬 크레딧 로드 (Firebase 실패 시)
    private func loadLocalCredits() {
        let savedCredits = UserDefaults.standard.integer(forKey: "ai_analysis_credits")
        let savedResetDate = UserDefaults.standard.object(forKey: "ai_analysis_reset_date") as? Date ?? Date()
        
        // 월이 바뀌었는지 확인
        let calendar = Calendar.current
        if calendar.component(.month, from: savedResetDate) != calendar.component(.month, from: Date()) {
            remainingCredits = monthlyFreeLimit
            lastResetDate = Date()
            UserDefaults.standard.set(0, forKey: "monthly_ad_rewards")
            saveLocalCredits()
        } else {
            remainingCredits = savedCredits > 0 ? savedCredits : monthlyFreeLimit
            lastResetDate = savedResetDate
        }
        
        print("📦 로컬 크레딧 사용: \(remainingCredits)회")
    }
    
    /// 로컬 크레딧 저장
    private func saveLocalCredits() {
        UserDefaults.standard.set(remainingCredits, forKey: "ai_analysis_credits")
        UserDefaults.standard.set(lastResetDate, forKey: "ai_analysis_reset_date")
    }
    
    /// 크레딧 사용 가능 여부 확인
    func canUseAIAnalysis() -> Bool {
        return remainingCredits > 0
    }
    
    /// 크레딧 차감 (Firebase 우선, 실패 시 로컬)
    private func useCredit() async throws {
        do {
            // Firebase에서 크레딧 차감 시도
            let success = try await usageTracker.consumeCredit()
            
            guard success else {
                throw AIAnalysisError.insufficientCredits
            }
            
            // @MainActor 클래스 안이므로 직접 수정
            if remainingCredits > 0 {
                remainingCredits -= 1
            }
            print("💳 Firebase 크레딧 차감: \(remainingCredits)회 남음")
            
        } catch {
            print("⚠️ Firebase 크레딧 차감 실패, 로컬로 대체: \(error)")
            
            // Fallback: 로컬 크레딧 차감
            guard remainingCredits > 0 else {
                throw AIAnalysisError.insufficientCredits
            }
            remainingCredits -= 1
            saveLocalCredits()
            print("💳 로컬 크레딧 차감: \(remainingCredits)회 남음")
        }
    }
    
    /// 광고 시청으로 크레딧 추가
    func addCreditsFromAd() async {
        do {
            // Firebase에서 광고 보상 추가
            try await usageTracker.addCreditsFromAd(amount: adRewardAmount)
            
            // 최신 크레딧 가져오기
            let credits = try await usageTracker.getRemainingCredits()
            
            remainingCredits = credits
            errorMessage = nil
            print("📺 광고 보상 완료: \(credits)회 남음 (추가: \(adRewardAmount)회)")
            
        } catch UsageError.adRewardLimitReached {
            errorMessage = NSLocalizedString("ad_reward_limit_reached", comment: "")
            print("⚠️ 광고 보상 한도 초과")
            
        } catch {
            print("⚠️ Firebase 광고 보상 실패, 로컬로 대체: \(error)")
            
            // Fallback: 로컬 광고 보상
            fallbackAddCreditsFromAd()
        }
    }
    
    /// Fallback: 로컬 광고 보상
    private func fallbackAddCreditsFromAd() {
        let currentAdRewards = UserDefaults.standard.integer(forKey: "monthly_ad_rewards")
        
        if currentAdRewards < maxAdRewards {
            remainingCredits += adRewardAmount
            UserDefaults.standard.set(currentAdRewards + 1, forKey: "monthly_ad_rewards")
            saveLocalCredits()
            errorMessage = nil
            print("📺 로컬 광고 보상: \(remainingCredits)회 남음 (추가: \(adRewardAmount)회)")
        } else {
            errorMessage = NSLocalizedString("ad_reward_limit_reached", comment: "")
        }
    }
    
    /// 남은 광고 보상 횟수 조회
    func getRemainingAdRewards() async -> Int {
        do {
            return try await usageTracker.getRemainingAdRewards()
        } catch {
            print("⚠️ Firebase 광고 횟수 조회 실패, 로컬 사용")
            let used = UserDefaults.standard.integer(forKey: "monthly_ad_rewards")
            return max(0, maxAdRewards - used)
        }
    }
    
    /// 크레딧 수동 갱신 (Pull to Refresh 등에서 사용)
    func refreshCredits() async {
        do {
            let credits = try await usageTracker.getRemainingCredits()
            remainingCredits = credits
            print("🔄 크레딧 갱신: \(credits)회")
        } catch {
            print("⚠️ 크레딧 갱신 실패: \(error)")
        }
    }
    
    // MARK: - AI 도안 분석 (하이브리드 방식)
    
    func analyzeKnittingPatternFile(fileData: Data, fileName: String) async {
        
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        
        print("🔍 [분석 시작] isAnalyzing = \(isAnalyzing)")
        
        do {
            // 파일 크기 확인 (20MB 제한)
            let maxFileSize = 20 * 1024 * 1024
            guard fileData.count <= maxFileSize else {
                print("❌ 파일 크기 초과 - 크레딧 미차감")
                throw AIAnalysisError.fileTooLarge
            }
            
            // 지원하는 파일 형식 확인
            guard isValidFileType(fileName: fileName) else {
                print("❌ 지원하지 않는 파일 형식 - 크레딧 미차감")
                throw AIAnalysisError.unsupportedFileType
            }
            
            // 크레딧 확인
            guard canUseAIAnalysis() else {
                print("❌ 크레딧 부족 - 분석 불가")
                throw AIAnalysisError.insufficientCredits
            }
            
            try await useCredit()
            print("✅ 크레딧 차감 완료 (남은 크레딧: \(remainingCredits))")
            print("🔍 [Claude API 호출 시작]")
            
            do {
                // Claude API의 하이브리드 분석 호출
                // PDF는 직접 처리 시도 후 실패시 이미지 변환 방식으로 fallback
                let result = try await claudeService.analyzeKnittingPattern(
                    fileData: fileData,
                    fileName: fileName
                )
                
                print("✅ [API 응답 받음]")
                
                // 분석 성공
                analysisResult = result
                isAnalyzing = false
                consecutiveFailures = 0  // 연속 실패 카운터 리셋
                
                // 성공 기록
                if let fileHash = try? usageTracker.calculateFileHash(fileData) {
                    try? await usageTracker.recordAnalysisAttempt(
                        fileHash: fileHash,
                        fileName: fileName,
                        success: true
                    )
                }
                
                print("✅ AI 파일 분석 완료: \(result.projectName)")
                print("🧶 파트 수: \(result.parts.count)")
                print("💳 남은 크레딧: \(remainingCredits)")
                
            } catch {
                // API 호출 후 실패 (크레딧은 이미 차감됨)
                consecutiveFailures += 1
                
                // 실패 기록
                if let fileHash = try? usageTracker.calculateFileHash(fileData) {
                    try? await usageTracker.recordAnalysisAttempt(
                        fileHash: fileHash,
                        fileName: fileName,
                        success: false
                    )
                }
                
                print("❌ API 호출 실패 (크레딧 소모됨): \(error)")
                throw AIAnalysisError.analysisFailedWithCreditUsed
            }
            
        } catch AIAnalysisError.analysisFailedWithCreditUsed {
            // 크레딧이 소모된 실패
            errorMessage = NSLocalizedString("analysis_failed_credit_used", comment: "")
            isAnalyzing = false
            print("⚠️ 분석 실패 - 크레딧 1회 사용됨")
            
        } catch {
            let errorKey: String
            if let analysisError = error as? AIAnalysisError {
                errorMessage = NSLocalizedString(analysisError.localizedDescription, comment: "")
            } else {
                errorMessage = NSLocalizedString("analysis_failed_no_credit", comment: "")
            }
            isAnalyzing = false
            print("❌ AI 파일 분석 실패 (크레딧 미소모): \(error)")
        }
    }
    
    // PDF 전용 분석 메서드 (2단계 통합 분석이 필요한 경우)
    func analyzePDFKnittingPattern(pdfData: Data, fileName: String) async {
        /*
         하이브리드 전략:
         1. ClaudeAPIService가 먼저 PDF 직접 처리 시도
         2. 실패시 자동으로 이미지 변환 방식으로 fallback
         3. 큰 PDF나 복잡한 경우에만 2단계 분석 사용
         */
        
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        
        print("📄 [PDF 분석 시작] isAnalyzing = \(isAnalyzing)")
        
        do {
            // 파일 크기 및 크레딧 확인
            let maxFileSize = 20 * 1024 * 1024
            guard pdfData.count <= maxFileSize else {
                print("❌ PDF 파일 크기 초과 - 크레딧 미차감")
                throw AIAnalysisError.fileTooLarge
            }
            guard canUseAIAnalysis() else {
                print("❌ 크레딧 부족 - 분석 불가")
                throw AIAnalysisError.insufficientCredits
            }
            
            try await useCredit()
            print("✅ 크레딧 차감 완료 (남은 크레딧: \(remainingCredits))")
            
            // 1차 시도: PDF 직접 처리 (ClaudeAPIService 내부에서 처리)
            do {
                let result = try await claudeService.analyzeKnittingPattern(
                    fileData: pdfData,
                    fileName: fileName
                )
                
                // 직접 처리 성공
                analysisResult = result
                isAnalyzing = false
                consecutiveFailures = 0
                
                // 성공 기록
                if let fileHash = try? usageTracker.calculateFileHash(pdfData) {
                    try? await usageTracker.recordAnalysisAttempt(
                        fileHash: fileHash,
                        fileName: fileName,
                        success: true
                    )
                }
                
                print("✅ PDF 직접 처리 성공: \(result.projectName)")
                print("🧶 파트 수: \(result.parts.count)")
                print("💳 남은 크레딧: \(remainingCredits)")
                
            } catch {
                // PDF 직접 처리 실패 - 2단계 분석으로 전환
                print("⚠️ PDF 직접 처리 실패, 2단계 분석 시작: \(error)")
                try await performTwoStageAnalysis(pdfData: pdfData, fileName: fileName)
            }
            
        } catch AIAnalysisError.analysisFailedWithCreditUsed {
            // 크레딧이 소모된 실패
            errorMessage = NSLocalizedString("analysis_failed_credit_used", comment: "")
            isAnalyzing = false
            print("⚠️ PDF 분석 실패 - 크레딧 1회 사용됨")
            
        } catch {
            // 크레딧이 소모되지 않은 실패
            if let analysisError = error as? AIAnalysisError {
                errorMessage = NSLocalizedString(analysisError.localizedDescription, comment: "")
            } else {
                errorMessage = NSLocalizedString("analysis_failed_no_credit", comment: "")
            }
            isAnalyzing = false
            print("❌ PDF AI 분석 실패 (크레딧 미소모): \(error)")
        }
    }
    
    // MARK: - 2단계 분석 시스템 (Fallback)
    
    private func performTwoStageAnalysis(pdfData: Data, fileName: String) async throws {
        // PDF를 이미지로 변환
        let pageImages = convertPDFToMultipleImages(pdfData: pdfData)
        guard !pageImages.isEmpty else {
            print("❌ PDF 이미지 변환 실패")
            throw AIAnalysisError.imageProcessingFailed
        }
        
        print("📄 PDF 페이지 수: \(pageImages.count)")
        print("🔍 1단계: 페이지별 분석 시작...")
        
        var pageAnalysisResults: [String] = []
        
        for (index, imageData) in pageImages.enumerated() {
            print("🔍 1단계: 페이지 \(index + 1)/\(pageImages.count) 분석 중...")
            
            do {
                // 각 페이지별 분석 수행 (특별 프롬프트 사용)
                let pageResult = try await claudeService.analyzeKnittingPatternPage(
                    fileData: imageData,
                    fileName: "\(fileName)_page\(index + 1).jpg",
                    pageNumber: index + 1,
                    totalPages: pageImages.count
                )
                
                // JSON 문자열로 변환하여 저장 (2단계 통합 분석에 사용)
                let jsonString = convertAnalysisToJSONString(pageResult)
                pageAnalysisResults.append(jsonString)
                
                print("✅ 페이지 \(index + 1) 분석 완료 - \(pageResult.parts.count)개 파트 발견")
                
            } catch {
                // 페이지별 분석 실패 시 빈 분석 JSON 추가하여 누락 방지
                print("⚠️ 페이지 \(index + 1) 분석 실패: \(error.localizedDescription)")
                let emptyAnalysisJSON = """
                {"projectName":"분석실패(페이지 \(index + 1))","parts":[]}
                """
                pageAnalysisResults.append(emptyAnalysisJSON)
            }
        }
        
        // 2단계: 페이지별 결과 통합 분석 시작
        print("🔗 2단계: 결과 통합 분석 중...")
        
        do {
            let consolidatedResult = try await claudeService.consolidatePageResults(
                pageResults: pageAnalysisResults,
                originalFileName: fileName
            )
            
            // 분석 성공
            analysisResult = consolidatedResult
            isAnalyzing = false
            consecutiveFailures = 0  // 연속 실패 카운터 리셋
            
            // 성공 기록
            if let fileHash = try? usageTracker.calculateFileHash(pdfData) {
                try? await usageTracker.recordAnalysisAttempt(
                    fileHash: fileHash,
                    fileName: fileName,
                    success: true
                )
            }
            
            print("✅ PDF 2단계 분석 완료: \(consolidatedResult.projectName)")
            print("🧶 최종 파트 수: \(consolidatedResult.parts.count)")
            print("📊 통합 비율: \(pageAnalysisResults.count)페이지 → \(consolidatedResult.parts.count)파트")
            print("💳 남은 크레딧: \(remainingCredits)")
            
        } catch {
            // 통합 분석 실패 (크레딧은 이미 차감됨)
            consecutiveFailures += 1
            
            // 실패 기록
            if let fileHash = try? usageTracker.calculateFileHash(pdfData) {
                try? await usageTracker.recordAnalysisAttempt(
                    fileHash: fileHash,
                    fileName: fileName,
                    success: false
                )
            }
            
            print("❌ PDF 통합 분석 실패 (크레딧 소모됨): \(error)")
            throw AIAnalysisError.analysisFailedWithCreditUsed
        }
    }
    
    // MARK: - Helper Methods
    
    /// 분석 결과를 JSON 문자열로 변환
    private func convertAnalysisToJSONString(_ analysis: KnittingAnalysis) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(analysis)
            return String(data: jsonData, encoding: .utf8) ?? "인코딩 실패"
        } catch {
            return "JSON 변환 실패: \(error.localizedDescription)"
        }
    }
    
    /// PDF를 여러 개의 개별 이미지로 변환 (5MB 이하로 최적화)
    private func convertPDFToMultipleImages(pdfData: Data) -> [Data] {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return []
        }
        
        let pageCount = pdfDocument.pageCount
        var imageDataArray: [Data] = []
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            
            // 이미지 크기 최적화 (5MB 제한 고려)
            let maxDimension: CGFloat = 2048
            let scale = min(maxDimension / pageRect.width, maxDimension / pageRect.height, 1.0)
            let scaledSize = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: scaledSize))
                
                ctx.cgContext.scaleBy(x: scale, y: scale)
                ctx.cgContext.translateBy(x: 0, y: pageRect.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            // JPEG 압축을 통해 파일 크기 최적화
            var compressionQuality: CGFloat = 0.8
            var imageData = image.jpegData(compressionQuality: compressionQuality)
            
            // 5MB를 초과하면 압축률 높이기
            while let data = imageData, data.count > 5 * 1024 * 1024 && compressionQuality > 0.3 {
                compressionQuality -= 0.1
                imageData = image.jpegData(compressionQuality: compressionQuality)
            }
            
            if let finalImageData = imageData {
                print("📸 페이지 \(pageIndex + 1): \(formatFileSize(finalImageData.count)), 압축률: \(compressionQuality)")
                imageDataArray.append(finalImageData)
            }
        }
        
        return imageDataArray
    }
    
    /// 파일 유효성 검사
    private func isValidFileType(fileName: String) -> Bool {
        let supportedExtensions = ["jpg", "jpeg", "png", "pdf", "heic", "heif"]
        let fileExtension = fileName.lowercased().components(separatedBy: ".").last ?? ""
        return supportedExtensions.contains(fileExtension)
    }
    
    /// 파일 크기 포맷팅
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Core Data 연동
    
    func createProjectFromAnalysis(_ analysis: KnittingAnalysis) -> Project {
        let project = coreDataManager.createProjectFromAI(analysis: analysis)
        print("🎉 AI 분석 결과로 프로젝트 생성 완료: \(project.name ?? "Unknown")")
        return project
    }
    
    // MARK: - 상태 정보
    
    func getUsageStatus() async -> String {
        let adRewardsRemaining = await getRemainingAdRewards()
        let usedAds = maxAdRewards - adRewardsRemaining
        
        return """
        📊 이번 달 사용 현황
        🆓 남은 무료 분석: \(remainingCredits)회
        📺 사용한 광고 보상: \(usedAds)/\(maxAdRewards)회
        🔄 다음 리셋: \(getNextResetDateString())
        ⚠️ 연속 실패: \(consecutiveFailures)회
        """
    }
    
    private func getNextResetDateString() -> String {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let components = calendar.dateComponents([.day], from: nextMonth)
        return "\(components.day ?? 1)일"
    }
    
    func resetAnalysisState() {
        analysisResult = nil
        errorMessage = nil
        isAnalyzing = false
        consecutiveFailures = 0
        print("🔄 분석 상태 초기화 완료")
    }
    
    /// 연속 실패에 대한 보너스 크레딧 제공 (옵션)
    func checkBonusCredit() async {
        // 3회 연속 실패 시 1크레딧 보너스 (월 1회 제한)
        if consecutiveFailures >= 3 {
            let bonusGiven = UserDefaults.standard.bool(forKey: "monthly_bonus_given")
            if !bonusGiven {
                remainingCredits += 1
                saveLocalCredits()
                UserDefaults.standard.set(true, forKey: "monthly_bonus_given")
                errorMessage = "연속 실패로 인해 보너스 크레딧 1회가 제공되었습니다."
                consecutiveFailures = 0
                print("🎁 보너스 크레딧 제공: \(remainingCredits)회")
            }
        }
    }
}

// MARK: - Error Types

enum AIAnalysisError: Error {
    case insufficientCredits
    case imageProcessingFailed
    case analysisTimeout
    case fileTooLarge
    case unsupportedFileType
    case firebaseError
    case networkError
    case analysisFailedWithCreditUsed  // 크레딧 소모된 실패
    
    var localizedDescription: String {
        switch self {
        case .insufficientCredits:
            return "insufficient_credits"
        case .imageProcessingFailed:
            return "image_process_failed"
        case .analysisTimeout:
            return "analysis_timeout"
        case .fileTooLarge:
            return "file_too_large"
        case .unsupportedFileType:
            return "unsupported_format"
        case .firebaseError:
            return "server_connection_failed"
        case .networkError:
            return "network_error"
        case .analysisFailedWithCreditUsed:
            return "analysis_failed_credit_used"
        }
    }
}
