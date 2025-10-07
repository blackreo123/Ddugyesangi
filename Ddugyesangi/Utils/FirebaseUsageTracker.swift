//
//  FirebaseUsageTracker.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/07.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseUsageTracker: ObservableObject {
    
    private let db = Firestore.firestore()
    private let monthlyLimit = 5
    
    @Published var isInitialized = false
    
    // 현재 인증된 사용자 UID
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - 초기화
    
    /// Firebase 익명 인증 초기화
    func initialize() async throws {
        // 이미 로그인되어 있는지 확인
        if Auth.auth().currentUser != nil {
            print("✅ 기존 Firebase 사용자 확인: \(Auth.auth().currentUser?.uid ?? "")")
            await MainActor.run {
                isInitialized = true
            }
            return
        }
        
        // Keychain에서 이전 UID 확인 (앱 재설치 대비)
        if let savedUID = KeychainHelper.load(key: "firebase_uid") {
            print("📦 Keychain에서 이전 UID 발견: \(savedUID)")
            // 실제로는 Custom Token 방식으로 복원해야 하지만
            // 지금은 새로 생성 (고급 기능은 서버 구현 필요)
        }
        
        // 새 익명 사용자 생성
        do {
            let result = try await Auth.auth().signInAnonymously()
            let uid = result.user.uid
            
            // Keychain에 UID 저장
            _ = KeychainHelper.save(key: "firebase_uid", value: uid)
            
            print("✅ Firebase 익명 사용자 생성: \(uid)")
            
            await MainActor.run {
                isInitialized = true
            }
        } catch {
            print("❌ Firebase 인증 실패: \(error.localizedDescription)")
            throw UsageError.authenticationFailed
        }
    }
    
    // MARK: - 사용량 관리
    
    /// 현재 남은 크레딧 조회
    func getRemainingCredits() async throws -> Int {
        guard let uid = currentUID else {
            throw UsageError.notAuthenticated
        }
        
        let docRef = db.collection("usage").document(uid)
        let document = try await docRef.getDocument()
        
        // 문서가 없으면 신규 사용자
        guard document.exists, let data = document.data() else {
            // 초기 크레딧 생성
            try await createInitialUsage(uid: uid)
            return monthlyLimit
        }
        
        // 월별 리셋 체크
        let lastResetDate = (data["lastResetDate"] as? Timestamp)?.dateValue() ?? Date()
        let needsReset = shouldResetCredits(lastResetDate: lastResetDate)
        
        if needsReset {
            try await resetMonthlyCredits(uid: uid)
            return monthlyLimit
        }
        
        return data["credits"] as? Int ?? 0
    }
    
    /// 크레딧 사용 (Transaction으로 동시성 제어)
    func consumeCredit() async throws -> Bool {
        guard let uid = currentUID else {
            throw UsageError.notAuthenticated
        }
        
        let docRef = db.collection("usage").document(uid)
        
        let result = try await db.runTransaction { transaction, errorPointer in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return false
            }
            
            // 문서가 없으면 실패
            guard document.exists, let data = document.data() else {
                let error = NSError(
                    domain: "UsageError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "사용량 문서 없음"]
                )
                errorPointer?.pointee = error
                return false
            }
            
            // 월별 리셋 체크
            let lastResetDate = (data["lastResetDate"] as? Timestamp)?.dateValue() ?? Date()
            let needsReset = self.shouldResetCredits(lastResetDate: lastResetDate)
            
            var credits: Int
            
            if needsReset {
                // 새 달 - 크레딧 리셋
                credits = self.monthlyLimit - 1
                transaction.updateData([
                    "credits": credits,
                    "lastResetDate": Timestamp(),
                    "lastUsed": Timestamp(),
                    "updatedAt": Timestamp()
                ], forDocument: docRef)
                
                print("🔄 월별 크레딧 리셋: \(credits + 1) → \(credits)")
            } else {
                // 현재 크레딧 확인
                guard var currentCredits = data["credits"] as? Int, currentCredits > 0 else {
                    let error = NSError(
                        domain: "UsageError",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "크레딧 부족"]
                    )
                    errorPointer?.pointee = error
                    return false
                }
                
                credits = currentCredits - 1
                transaction.updateData([
                    "credits": credits,
                    "lastUsed": Timestamp(),
                    "updatedAt": Timestamp()
                ], forDocument: docRef)
                
                print("💳 크레딧 사용: \(currentCredits) → \(credits)")
            }
            
            return true
        }
        
        return result as? Bool ?? false
    }
    
    /// 광고 시청으로 크레딧 추가
    func addCreditsFromAd(amount: Int = 5) async throws {
        guard let uid = currentUID else {
            throw UsageError.notAuthenticated
        }
        
        let docRef = db.collection("usage").document(uid)
        
        try await db.runTransaction { transaction, errorPointer in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard document.exists, let data = document.data() else {
                return nil
            }
            
            let currentCredits = data["credits"] as? Int ?? 0
            let adRewardsUsed = data["adRewardsUsed"] as? Int ?? 0
            let maxAdRewards = 3  // 한 달에 최대 3번
            
            // 광고 보상 한도 체크
            guard adRewardsUsed < maxAdRewards else {
                let error = NSError(
                    domain: "UsageError",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "광고 보상 한도 초과"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let newCredits = currentCredits + amount
            let newAdRewards = adRewardsUsed + 1
            
            transaction.updateData([
                "credits": newCredits,
                "adRewardsUsed": newAdRewards,
                "lastAdReward": Timestamp(),
                "updatedAt": Timestamp()
            ], forDocument: docRef)
            
            print("📺 광고 보상 추가: \(currentCredits) → \(newCredits) (보상 횟수: \(newAdRewards)/\(maxAdRewards))")
            
            return newCredits
        }
    }
    
    /// 남은 광고 보상 횟수 조회
    func getRemainingAdRewards() async throws -> Int {
        guard let uid = currentUID else {
            throw UsageError.notAuthenticated
        }
        
        let docRef = db.collection("usage").document(uid)
        let document = try await docRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            return 3  // 신규 사용자는 3회 가능
        }
        
        let adRewardsUsed = data["adRewardsUsed"] as? Int ?? 0
        return max(0, 3 - adRewardsUsed)
    }
    
    // MARK: - Private Helpers
    
    /// 초기 사용량 문서 생성
    private func createInitialUsage(uid: String) async throws {
        let initialData: [String: Any] = [
            "credits": monthlyLimit,
            "lastResetDate": Timestamp(),
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "adRewardsUsed": 0
        ]
        
        try await db.collection("usage").document(uid).setData(initialData)
        print("✅ 초기 사용량 문서 생성: \(monthlyLimit)크레딧")
    }
    
    /// 월별 크레딧 리셋 필요 여부 확인
    private func shouldResetCredits(lastResetDate: Date) -> Bool {
        let calendar = Calendar.current
        let lastMonth = calendar.component(.month, from: lastResetDate)
        let lastYear = calendar.component(.year, from: lastResetDate)
        
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return lastYear != currentYear || lastMonth != currentMonth
    }
    
    /// 월별 크레딧 리셋
    private func resetMonthlyCredits(uid: String) async throws {
        let docRef = db.collection("usage").document(uid)
        
        try await docRef.updateData([
            "credits": monthlyLimit,
            "lastResetDate": Timestamp(),
            "updatedAt": Timestamp(),
            "adRewardsUsed": 0  // 광고 보상도 리셋
        ])
        
        print("🔄 월별 크레딧 리셋 완료: \(monthlyLimit)크레딧")
    }
}

// MARK: - Error Types

enum UsageError: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case insufficientCredits
    case adRewardLimitReached
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "인증되지 않은 사용자입니다."
        case .authenticationFailed:
            return "Firebase 인증에 실패했습니다."
        case .insufficientCredits:
            return "AI 분석 크레딧이 부족합니다."
        case .adRewardLimitReached:
            return "이번 달 광고 보상 한도에 도달했습니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        }
    }
}
