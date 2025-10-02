//
//  AIAnalysisManager.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/03.
//

import Foundation
import UIKit

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
    func analyzeKnittingPattern(image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        do {
            // 이미지 데이터 변환
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw AIAnalysisError.imageProcessingFailed
            }
            
            // 크레딧 확인
            guard canUseAIAnalysis() else {
                throw AIAnalysisError.insufficientCredits
            }
            
            // AI 분석 실행
            let result = try await claudeService.analyzeKnittingPattern(imageData: imageData)
            
            // 성공시 크레딧 차감 및 결과 저장
            await MainActor.run {
                useCredit()
                analysisResult = result
                isAnalyzing = false
                print("✅ AI 분석 완료: \(result.projectName)")
                print("🧶 파트 수: \(result.parts.count)")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
                print("❌ AI 분석 실패: \(error)")
            }
        }
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
    
    var localizedDescription: String {
        switch self {
        case .insufficientCredits:
            return "AI 분석 크레딧이 부족합니다. 광고를 시청하여 크레딧을 얻으세요."
        case .imageProcessingFailed:
            return "이미지 처리에 실패했습니다."
        case .analysisTimeout:
            return "분석 시간이 초과되었습니다. 다시 시도해주세요."
        }
    }
}
