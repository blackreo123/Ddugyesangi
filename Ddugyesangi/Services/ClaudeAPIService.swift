//
//  ClaudeAPIService.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/09/22.
//

import Foundation
import Alamofire

class ClaudeAPIService {
    private let apiKey: String
    private let baseURL = Constants.Claude.baseURL
    private let anthropicVersion = Constants.Claude.anthropicVersion
    private var cachedModels: [ModelsResponse.ClaudeModel] = []
    private var lastModelsFetch: Date?
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - 모델 리스트 가져오기
    private func fetchAvailableModels() async throws -> [ModelsResponse.ClaudeModel] {
        // 캐시된 모델이 있고 설정된 시간 이내에 가져온 것이면 캐시 사용
        if let lastFetch = lastModelsFetch,
           Date().timeIntervalSince(lastFetch) < Constants.Claude.modelCacheExpiration,
           !cachedModels.isEmpty {
            print("🔄 캐시된 모델 리스트 사용")
            return cachedModels
        }
        
        let url = "\(baseURL)/models"
        
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "anthropic-version": anthropicVersion
        ]
        
        print("🔍 모델 리스트 가져오는 중...")
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .get, headers: headers)
                .validate()
                .responseDecodable(of: ModelsResponse.self) { response in
                    switch response.result {
                    case .success(let modelsResponse):
                        let models = modelsResponse.data
                        print("✅ \(models.count)개 모델 발견:")
                        for model in models {
                            print("  - \(model.id) (\(model.displayName))")
                        }
                        
                        // 캐시 업데이트
                        self.cachedModels = models
                        self.lastModelsFetch = Date()
                        
                        continuation.resume(returning: models)
                    case .failure(let error):
                        print("❌ 모델 리스트 가져오기 실패: \(error)")
                        // 실패한 경우 폴백 모델 리스트 사용
                        let fallbackModels = self.getFallbackModels()
                        print("🔄 폴백 모델 리스트 사용: \(fallbackModels.map { $0.id })")
                        continuation.resume(returning: fallbackModels)
                    }
                }
        }
    }
    
    // MARK: - 폴백 모델 리스트
    private func getFallbackModels() -> [ModelsResponse.ClaudeModel] {
        return [
            ModelsResponse.ClaudeModel(id: "claude-3-5-sonnet-20241022", type: "model", displayName: "Claude 3.5 Sonnet", createdAt: "2024-10-22"),
            ModelsResponse.ClaudeModel(id: "claude-3-5-sonnet-20240620", type: "model", displayName: "Claude 3.5 Sonnet", createdAt: "2024-06-20"),
            ModelsResponse.ClaudeModel(id: "claude-3-sonnet-20240229", type: "model", displayName: "Claude 3 Sonnet", createdAt: "2024-02-29"),
            ModelsResponse.ClaudeModel(id: "claude-3-haiku-20240307", type: "model", displayName: "Claude 3 Haiku", createdAt: "2024-03-07"),
            ModelsResponse.ClaudeModel(id: "claude-3-opus-20240229", type: "model", displayName: "Claude 3 Opus", createdAt: "2024-02-29")
        ]
    }
    
    // MARK: - 최적 모델 선택
    private func selectBestModel(from models: [ModelsResponse.ClaudeModel]) -> ModelsResponse.ClaudeModel? {
        // 비전 기능이 있는 모델만 필터링 (이미지 분석용)
        let visionCapableModels = models.filter { model in
            model.id.contains("claude-3") || model.id.contains("sonnet") || model.id.contains("haiku") || model.id.contains("opus")
        }
        
        // 우선순위: Sonnet > Opus > Haiku 순으로, 날짜가 최신인 것 우선
        let prioritizedModels = visionCapableModels.sorted { model1, model2 in
            // 1. Sonnet 모델 우선
            let model1IsSonnet = model1.id.contains("sonnet")
            let model2IsSonnet = model2.id.contains("sonnet")
            
            if model1IsSonnet && !model2IsSonnet {
                return true
            } else if !model1IsSonnet && model2IsSonnet {
                return false
            }
            
            // 2. 같은 계열이면 날짜순 (최신 우선)
            return model1.createdAt > model2.createdAt
        }
        
        return prioritizedModels.first
    }
    
    // MARK: - 뜨개질 도안 분석 메인 함수
    func analyzeKnittingPattern(imageData: Data) async throws -> KnittingAnalysis {
        let prompt = """
        뜨개질 도안 이미지를 분석해서 다음 정보를 JSON 형태로 정확하게 제공해주세요:

        {
            "projectName": "도안의 이름 또는 추정되는 이름",
            "parts": [
                {
                    "partName": "파트 이름 (예: 앞판, 뒷판, 소매, 몸통 등)",
                    "targetRow": 목표 단수 (숫자만),
                    "stitchGuide": [
                        {
                            "row": 단수,
                            "targetStitch": 해당 단수의 목표 코수
                        }
                    ]
                }
            ]
        }

        주의사항:
        - 모든 숫자는 정수로만 표현
        - stitchGuide는 단수별 코수 정보 배열
        - JSON 형식을 정확하게 맞춰주세요
        """
        
        let response = try await sendMessage(imageData: imageData, prompt: prompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    // MARK: - Claude API 호출
    private func sendMessage(imageData: Data, prompt: String) async throws -> String {
        let url = "\(baseURL)/messages"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": anthropicVersion
        ]
        
        // 디버깅 로그 추가
        print("🔗 API URL: \(url)")
        print("🔑 API Key 길이: \(apiKey.count) characters")
        print("🔑 API Key 시작: \(String(apiKey.prefix(10)))...")
        print("📋 Anthropic Version: \(anthropicVersion)")
        
        let base64Image = imageData.base64EncodedString()
        
        // 사용 가능한 모델 리스트 가져오기
        let availableModels = try await fetchAvailableModels()
        
        // 최적 모델 선택
        guard let bestModel = selectBestModel(from: availableModels) else {
            throw ClaudeAPIError.networkError("사용 가능한 모델이 없습니다.")
        }
        
        print("🎯 선택된 최적 모델: \(bestModel.id) (\(bestModel.displayName))")
        
        // 선택된 모델부터 시작해서 폴백 모델들도 순서대로 시도
        let modelsToTry = [bestModel] + availableModels.filter { $0.id != bestModel.id }
        
        for model in modelsToTry.prefix(3) { // 최대 3개 모델만 시도
            print("🔄 시도 중인 모델: \(model.id)")
            
            let parameters: [String: Any] = [
                "model": model.id,
                "max_tokens": 2000,
                "temperature": 0.1,
                "messages": [
                    [
                        "role": "user",
                        "content": [
                            [
                                "type": "image",
                                "source": [
                                    "type": "base64",
                                    "media_type": "image/jpeg",
                                    "data": base64Image
                                ]
                            ],
                            [
                                "type": "text",
                                "text": prompt
                            ]
                        ]
                    ]
                ]
            ]
            
            do {
                let result = try await makeAPIRequest(url: url, parameters: parameters, headers: headers, model: model.id)
                print("✅ 성공한 모델: \(model.id)")
                return result
            } catch {
                print("❌ 모델 \(model.id) 실패: \(error)")
                // 404 오류가 아닌 경우에는 재시도하지 않고 바로 오류 던지기
                if let afError = error as? ClaudeAPIError,
                   case .networkError(let message) = afError,
                   !message.contains("404") && !message.contains("not_found_error") {
                    throw error
                }
                continue
            }
        }
        
        throw ClaudeAPIError.networkError("사용 가능한 모델이 없습니다.")
    }
    
    // MARK: - API 요청 실행
    private func makeAPIRequest(url: String, parameters: [String: Any], headers: HTTPHeaders, model: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: ClaudeResponse.self) { response in
                    // 상세한 응답 로깅
                    print("📡 HTTP Status Code: \(response.response?.statusCode ?? -1)")
                    print("📊 Response Headers: \(response.response?.allHeaderFields ?? [:])")
                    
                    if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Raw Response: \(responseString)")
                    }
                    
                    switch response.result {
                    case .success(let claudeResponse):
                        let content = claudeResponse.content.first?.text ?? ""
                        print("✅ API 응답 성공, 컨텐츠 길이: \(content.count)")
                        continuation.resume(returning: content)
                    case .failure(let error):
                        print("❌ Claude API 에러: \(error)")
                        print("❌ Error Details: \(error.localizedDescription)")
                        if let afError = error.asAFError {
                            print("❌ AFError Description: \(afError)")
                        }
                        continuation.resume(throwing: ClaudeAPIError.networkError(error.localizedDescription))
                    }
                }
        }
    }
    
    // MARK: - 공개 메소드들
    
    /// 모델 리스트를 강제로 새로고침
    func refreshModels() async {
        cachedModels = []
        lastModelsFetch = nil
        do {
            _ = try await fetchAvailableModels()
        } catch {
            print("❌ 모델 리스트 새로고침 실패: \(error)")
        }
    }
    
    /// 현재 캐시된 모델 리스트 반환
    func getCachedModels() -> [ModelsResponse.ClaudeModel] {
        return cachedModels
    }
    
    // MARK: - JSON 응답 파싱
    private func parseKnittingAnalysis(from response: String) throws -> KnittingAnalysis {
        print("📝 Claude 응답: \(response)")
        
        // JSON 부분만 추출
        let jsonString = extractJSON(from: response)
        print("🔍 추출된 JSON: \(jsonString)")
        
        guard let data = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(KnittingAnalysis.self, from: data)
        } catch {
            print("❌ JSON 파싱 에러: \(error)")
            print("📄 원본 응답: \(response)")
            throw ClaudeAPIError.parsingFailed
        }
    }
    
    private func extractJSON(from text: String) -> String {
        // ```json으로 시작하고 ```로 끝나는 부분 추출
        if let startRange = text.range(of: "```json") {
            let afterStart = String(text[startRange.upperBound...])
            if let endRange = afterStart.range(of: "```") {
                return String(afterStart[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // { }로 둘러싸인 JSON 부분 찾기
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        return text
    }
}

// MARK: - 응답 모델들
struct ClaudeResponse: Codable {
    let content: [ContentBlock]
    
    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
}

// MARK: - 모델 리스트 응답 구조체
struct ModelsResponse: Codable {
    let data: [ClaudeModel]
    
    struct ClaudeModel: Codable {
        let id: String
        let type: String
        let displayName: String
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id, type
            case displayName = "display_name"
            case createdAt = "created_at"
        }
    }
}

enum ClaudeAPIError: Error {
    case invalidResponse
    case parsingFailed
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "AI 응답 형식이 올바르지 않습니다."
        case .parsingFailed:
            return "AI 응답을 분석할 수 없습니다."
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        }
    }
}
