//
//  AIAnalysisManager.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/03.
//

import Foundation
import UIKit
import PDFKit

class AIAnalysisManager: ObservableObject {
    static let shared = AIAnalysisManager()
    
    @Published var remainingCredits: Int = 0
    @Published var lastResetDate: Date = Date()
    @Published var isAnalyzing: Bool = false
    @Published var analysisResult: KnittingAnalysis?
    @Published var errorMessage: String?
    
    private let claudeService: ClaudeAPIService
    private let userDefaults = UserDefaults.standard
    private let coreDataManager = CoreDataManager.shared
    
    // 사용량 제한 상수
    private let monthlyFreeLimit = 10
    private let adRewardAmount = 5
    private let maxAdRewards = 3
    
    private init() {
        self.claudeService = ClaudeAPIService(apiKey: Constants.Claude.apiKey)
        loadUserCredits()
    }
    
    // MARK: - 크레딧 관리
    private func loadUserCredits() {
        let savedCredits = userDefaults.integer(forKey: "ai_analysis_credits")
        let savedResetDate = userDefaults.object(forKey: "ai_analysis_reset_date") as? Date ?? Date()
        
        // 월이 바뀌었는지 확인
        if Calendar.current.component(.month, from: savedResetDate) != Calendar.current.component(.month, from: Date()) {
            resetMonthlyCredits()
        } else {
            remainingCredits = savedCredits > 0 ? savedCredits : monthlyFreeLimit
            lastResetDate = savedResetDate
        }
    }
    
    private func resetMonthlyCredits() {
        remainingCredits = monthlyFreeLimit
        lastResetDate = Date()
        userDefaults.set(0, forKey: "monthly_ad_rewards") // 광고 보상도 리셋
        saveUserCredits()
    }
    
    private func saveUserCredits() {
        userDefaults.set(remainingCredits, forKey: "ai_analysis_credits")
        userDefaults.set(lastResetDate, forKey: "ai_analysis_reset_date")
    }
    
    // MARK: - 크레딧 확인 및 관리
    func canUseAIAnalysis() -> Bool {
        return remainingCredits > 0
    }
    
    private func useCredit() {
        guard remainingCredits > 0 else { return }
        remainingCredits -= 1
        saveUserCredits()
    }
    
    func addCreditsFromAd() {
        let currentAdRewards = userDefaults.integer(forKey: "monthly_ad_rewards")
        
        if currentAdRewards < maxAdRewards {
            remainingCredits += adRewardAmount
            userDefaults.set(currentAdRewards + 1, forKey: "monthly_ad_rewards")
            saveUserCredits()
        }
    }
    
    func getRemainingAdRewards() -> Int {
        let used = userDefaults.integer(forKey: "monthly_ad_rewards")
        return max(0, maxAdRewards - used)
    }
    
    // MARK: - AI 도안 분석
    func analyzeKnittingPatternFile(fileData: Data, fileName: String) async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        do {
            // 파일 크기 확인 (20MB 제한)
            let maxFileSize = 20 * 1024 * 1024 // 20MB in bytes
            guard fileData.count <= maxFileSize else {
                throw AIAnalysisError.fileTooLarge
            }
            
            // 지원하는 파일 형식 확인
            guard isValidFileType(fileName: fileName) else {
                throw AIAnalysisError.unsupportedFileType
            }
            
            // 크레딧 확인
            guard canUseAIAnalysis() else {
                throw AIAnalysisError.insufficientCredits
            }
            
            // AI 분석 실행
            let result = try await claudeService.analyzeKnittingPattern(fileData: fileData, fileName: fileName)
            
            // 성공시 크레딧 차감 및 결과 저장
            await MainActor.run {
                useCredit()
                analysisResult = result
                isAnalyzing = false
                print("✅ AI 파일 분석 완료: \(result.projectName)")
                print("🧶 파트 수: \(result.parts.count)")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
                print("❌ AI 파일 분석 실패: \(error)")
            }
        }
    }
    
    // PDF 전용 분석 메서드 (2단계 통합 분석 시스템)
    func analyzePDFKnittingPattern(pdfData: Data, fileName: String) async {
        /*
         2단계 Claude 분석 전략
         
         1단계: PDF의 각 페이지를 이미지로 변환 후 페이지별 분석을 수행하여 JSON 결과를 수집
         2단계: 수집된 JSON 결과들을 텍스트로 변환하여 Claude API에 전달, 통합 분석 결과를 받아 최종 도안 생성
         
         각 페이지 분석 실패 시 빈 분석 JSON을 추가하여 통합 분석에서 누락되지 않도록 보완
         */
        
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        do {
            // 파일 크기 및 크레딧 확인
            let maxFileSize = 20 * 1024 * 1024
            guard pdfData.count <= maxFileSize else { throw AIAnalysisError.fileTooLarge }
            guard canUseAIAnalysis() else { throw AIAnalysisError.insufficientCredits }
            
            // 1단계: 페이지별 분석 시작
            let pageImages = convertPDFToMultipleImages(pdfData: pdfData)
            guard !pageImages.isEmpty else { throw AIAnalysisError.imageProcessingFailed }
            
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
            let consolidatedResult = try await claudeService.consolidatePageResults(
                pageResults: pageAnalysisResults,
                originalFileName: fileName
            )
            
            // 성공시 크레딧 차감 및 결과 저장
            await MainActor.run {
                useCredit()
                analysisResult = consolidatedResult
                isAnalyzing = false
                print("✅ PDF 2단계 분석 완료: \(consolidatedResult.projectName)")
                print("🧶 최종 파트 수: \(consolidatedResult.parts.count)")
                print("📊 통합 비율: \(pageAnalysisResults.count)페이지 → \(consolidatedResult.parts.count)파트")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
                print("❌ PDF AI 분석 실패: \(error)")
            }
        }
    }
    
    // 분석 결과를 JSON 문자열로 변환
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
    
    // PDF를 여러 개의 개별 이미지로 변환 (5MB 이하로 최적화)
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
            let maxDimension: CGFloat = 2048 // 적절한 해상도로 제한
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

    
    // MARK: - 파일 유효성 검사
    private func isValidFileType(fileName: String) -> Bool {
        let supportedExtensions = ["jpg", "jpeg", "png", "pdf", "heic", "heif"]
        let fileExtension = fileName.lowercased().components(separatedBy: ".").last ?? ""
        return supportedExtensions.contains(fileExtension)
    }
    
    // 파일 크기 포맷팅 헬퍼 (AIAnalysisManager 내부용)
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
        coreDataManager.printSmartPartsStatus()
        
        return project
    }
    
    // MARK: - 상태 정보
    func getUsageStatus() -> String {
        let usedAds = userDefaults.integer(forKey: "monthly_ad_rewards")
        return """
        📊 이번 달 사용 현황
        🆓 남은 무료 분석: \(remainingCredits)회
        📺 사용한 광고 보상: \(usedAds)/\(maxAdRewards)회
        📅 다음 리셋: \(getNextResetDateString())
        """
    }
    
    private func getNextResetDateString() -> String {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastResetDate) ?? Date()
        let components = calendar.dateComponents([.day], from: nextMonth)
        return "\(components.day ?? 1)일"
    }
}

enum AIAnalysisError: Error {
    case insufficientCredits
    case imageProcessingFailed
    case analysisTimeout
    case fileTooLarge
    case unsupportedFileType
    
    var localizedDescription: String {
        switch self {
        case .insufficientCredits:
            return "AI 분석 크레딧이 부족합니다. 광고를 시청하여 크레딧을 얻으세요."
        case .imageProcessingFailed:
            return "이미지 처리에 실패했습니다."
        case .analysisTimeout:
            return "분석 시간이 초과되었습니다. 다시 시도해주세요."
        case .fileTooLarge:
            return "파일 크기가 너무 큽니다. 20MB 이하의 파일을 선택해주세요."
        case .unsupportedFileType:
            return "지원하지 않는 파일 형식입니다. JPG, PNG, PDF, HEIC 파일만 지원합니다."
        }
    }
}

