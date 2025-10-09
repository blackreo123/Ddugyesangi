//
//  ClaudeAPIService.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/09/22.
//

import Foundation
import Alamofire

/// Claude API 하이브리드 PDF 처리 시스템
///
/// PDF 처리 전략:
/// 1. 우선: PDF 직접 API 전송 (네이티브 PDF 지원)
/// 2. Fallback: 기존 2단계 이미지 변환 방식
///
/// 일반 이미지는 기존 방식 유지

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
        // 비전 기능이 있는 모델만 필터링 (이미지/PDF 분석용)
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
    
    // MARK: - 뜨개질 도안 분석 메인 함수 (하이브리드)
    func analyzeKnittingPattern(fileData: Data, fileName: String = "") async throws -> KnittingAnalysis {
        // PDF 파일인 경우 직접 처리 시도
        if fileName.lowercased().hasSuffix(".pdf") {
            print("📄 PDF 직접 처리 시도...")
            
            do {
                // PDF 네이티브 API 호출 시도
                let result = try await analyzePDFDirect(pdfData: fileData, fileName: fileName)
                print("✅ PDF 직접 처리 성공!")
                return result
            } catch {
                print("⚠️ PDF 직접 처리 실패, 기존 이미지 변환 방식으로 fallback: \(error)")
                // Fallback: 기존 이미지 변환 방식 사용
                return try await analyzePDFWithImageConversion(pdfData: fileData, fileName: fileName)
            }
        }
        
        // 일반 이미지 파일 처리 (기존 방식)
        return try await analyzeImageFile(fileData: fileData, fileName: fileName)
    }
    
    // MARK: - PDF 직접 처리 (새로운 방식)
    private func analyzePDFDirect(pdfData: Data, fileName: String) async throws -> KnittingAnalysis {
        let base64PDF = pdfData.base64EncodedString()
        
        let prompt = """
        업로드된 뜨개질 도안 PDF 파일을 분석해서 다음 정보를 JSON 형태로 정확하게 제공해주세요:

        {
            "projectName": "도안의 이름 또는 추정되는 이름",
            "parts": [
                {
                    "partName": "파트 이름 (예: 앞판, 뒷판, 소매, 몸통 등)",
                    "targetRow": 목표 단수 (숫자만)
                }
            ]
        }

        주의사항:
        - PDF의 모든 페이지를 종합적으로 분석하세요
        - 차트, 도식, 텍스트를 모두 고려하세요
        - 모든 숫자는 정수로만 표현
        - JSON 형식을 정확하게 맞춰주세요
        - 중복된 파트는 하나로 통합하세요
        """
        
        let url = "\(baseURL)/messages"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": anthropicVersion
        ]
        
        // 사용 가능한 모델 가져오기
        let availableModels = try await fetchAvailableModels()
        
        guard let bestModel = selectBestModel(from: availableModels) else {
            throw ClaudeAPIError.networkError("사용 가능한 모델이 없습니다.")
        }
        
        print("🎯 PDF 직접 처리용 모델: \(bestModel.id)")
        
        let parameters: [String: Any] = [
            "model": bestModel.id,
            "max_tokens": 3000,
            "temperature": 0.1,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "document",
                            "source": [
                                "type": "base64",
                                "media_type": "application/pdf",
                                "data": base64PDF
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
        
        let result = try await makeAPIRequest(url: url, parameters: parameters, headers: headers, model: bestModel.id)
        return try parseKnittingAnalysis(from: result)
    }
    
    // MARK: - 이미지 파일 분석 (기존 방식)
    private func analyzeImageFile(fileData: Data, fileName: String) async throws -> KnittingAnalysis {
        let prompt = """
        업로드된 뜨개질 도안 파일을 분석해서 다음 정보를 JSON 형태로 정확하게 제공해주세요:

        {
            "projectName": "도안의 이름 또는 추정되는 이름",
            "parts": [
                {
                    "partName": "파트 이름 (예: 앞판, 뒷판, 소매, 몸통 등)",
                    "targetRow": 목표 단수 (숫자만)
                }
            ]
        }

        주의사항:
        - 모든 숫자는 정수로만 표현
        - JSON 형식을 정확하게 맞춰주세요
        """
        
        let response = try await sendMessage(fileData: fileData, fileName: fileName, prompt: prompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    // MARK: - PDF 이미지 변환 방식 (Fallback)
    private func analyzePDFWithImageConversion(pdfData: Data, fileName: String) async throws -> KnittingAnalysis {
        print("🔄 PDF를 이미지로 변환하여 처리 (Fallback 모드)...")
        
        // 기존 2단계 분석 시스템 사용
        // AIAnalysisManager의 analyzePDFKnittingPattern 로직을 여기서 호출
        
        // 임시로 에러 throw (실제로는 AIAnalysisManager와 연동 필요)
        throw ClaudeAPIError.networkError("PDF 이미지 변환 처리는 AIAnalysisManager를 통해 수행하세요.")
    }
    
    // MARK: - 2단계 분석 시스템 (기존 유지)
    
    /// 1단계: 페이지별 분석 (맥락 정보 포함)
    func analyzeKnittingPatternPage(
        fileData: Data,
        fileName: String,
        pageNumber: Int,
        totalPages: Int
    ) async throws -> KnittingAnalysis {
        
        let pagePrompt = """
        이것은 뜨개질 도안의 페이지 \(pageNumber)/\(totalPages) 입니다.

        **중요 지침**:
        1. 이 페이지에서 보이는 파트만 추출하세요
        2. 파트 이름에 반드시 "(페이지 \(pageNumber))" 표시를 추가하세요
        3. 부분 정보만 있어도 괜찮습니다
        4. 단순 사진/재료 설명만 있으면 parts: [] 빈 배열로 응답하세요
        5. 차트나 도식이 있으면 최대한 정확히 분석하세요
        6. "targetRow" 값은 반드시 Int(정수) 한 개만 넣으세요. 만약 '34~37단', '50~51단'처럼 범위로 표기되어 있다면, 해당 파트에 대해 가능한 한 구체적이고 합리적인 정수 단위 목표 단수를 하나로만 제공하세요. 숫자가 아닌 구간 표기/문자열 등은 절대 사용하지 마세요.

        JSON 형식으로 출력:
        {
            "projectName": "전체 프로젝트 추정 이름",
            "parts": [
                {
                    "partName": "파트이름 (페이지 \(pageNumber))",
                    "targetRow": 목표단수또는null
                }
            ]
        }

        주의: null 값도 허용하되, 가능한 한 구체적인 정보를 추출하세요.
        """
        
        let response = try await sendMessage(fileData: fileData, fileName: fileName, prompt: pagePrompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    /// 2단계: 텍스트 기반 통합 분석
    func consolidatePageResults(
        pageResults: [String],
        originalFileName: String
    ) async throws -> KnittingAnalysis {
        
        let consolidatedText = pageResults.joined(separator: "\n\n")
        
        let consolidationPrompt = """
        다음은 뜨개질 도안 PDF의 각 페이지별 분석 결과입니다:

        \(consolidatedText)

        **통합 작업을 수행하세요**:
        1. 같은 파트 병합 (예: "뒷판 (페이지 3)" + "뒷판 (페이지 7)" → "뒷판")
        2. 중복된 파트 제거하고 정보 통합
        3. "(페이지 X)" 표시 제거
        4. 핵심 파트만 선별 (불필요한 파트 제거)
        5. 프로젝트명을 가장 구체적이고 의미있는 이름으로 결정
        6. null 값들을 합리적인 기본값으로 대체

        **품질 기준**:
        - 최종 파트는 3-8개 정도가 적절
        - 각 파트는 명확한 목적을 가져야 함
        - 중복 정보는 철저히 제거

        최종 JSON 출력:
        {
            "projectName": "최종 프로젝트명",
            "parts": [
                {
                    "partName": "통합된 파트명",
                    "targetRow": 목표단수
                }
            ]
        }
        """
        
        // 텍스트 전용으로 Claude API 호출
        let response = try await sendTextMessage(prompt: consolidationPrompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    // MARK: - Claude API 호출
    
    /// 텍스트 전용 메시지 전송
    private func sendTextMessage(prompt: String) async throws -> String {
        let url = "\(baseURL)/messages"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": anthropicVersion
        ]
        
        print("🔗 텍스트 전용 API 호출")
        print("📝 프롬프트 길이: \(prompt.count) characters")
        
        // 사용 가능한 모델 리스트 가져오기
        let availableModels = try await fetchAvailableModels()
        
        // 최적 모델 선택
        guard let bestModel = selectBestModel(from: availableModels) else {
            throw ClaudeAPIError.networkError("사용 가능한 모델이 없습니다.")
        }
        
        print("🎯 통합 분석용 모델: \(bestModel.id)")
        
        let parameters: [String: Any] = [
            "model": bestModel.id,
            "max_tokens": 3000,
            "temperature": 0.1,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        return try await makeAPIRequest(url: url, parameters: parameters, headers: headers, model: bestModel.id)
    }
    
    private func sendMessage(fileData: Data, fileName: String, prompt: String) async throws -> String {
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
        
        print("📁 파일명: \(fileName)")
        print("📊 파일 크기: \(fileData.count) bytes")
        
        let base64Data = fileData.base64EncodedString()
        
        // 파일 확장자에 따른 미디어 타입 결정
        let mediaType = getMediaType(from: fileName)
        
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
                                    "media_type": mediaType,
                                    "data": base64Data
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
    
    // MARK: - 파일 타입 결정
    private func getMediaType(from fileName: String) -> String {
        let lowercasedFileName = fileName.lowercased()
        
        if lowercasedFileName.hasSuffix(".jpg") || lowercasedFileName.hasSuffix(".jpeg") {
            return "image/jpeg"
        } else if lowercasedFileName.hasSuffix(".png") {
            return "image/png"
        } else if lowercasedFileName.hasSuffix(".heic") || lowercasedFileName.hasSuffix(".heif") {
            return "image/heic"
        } else if lowercasedFileName.hasSuffix(".pdf") {
            return "application/pdf"
        } else {
            // 기본값으로 JPEG 사용
            return "image/jpeg"
        }
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
        print("🔍 Claude 응답: \(response)")
        
        // JSON 부분만 추출
        let jsonString = extractJSON(from: response)
        print("📋 추출된 JSON: \(jsonString)")
        
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
