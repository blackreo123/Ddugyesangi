//
//  ClaudeAPIService.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/09/22.
//

import Foundation
import Alamofire

/// Claude API 제약하 2단계 뜨개질 도안 분석 전략
///
/// 1단계: PDF 각 페이지 이미지를 analyzeKnittingPatternPage로 개별 분석 (파트명에 (페이지 N) 포함)
/// 2단계: 각 페이지별 결과(pageResults) 배열을 consolidatePageResults로 전달하여 중복/병합 포함 최종 통합 결과 생성
///
/// 예시 사용 흐름:
/// ----------------------------------------------------
/// var pageResults: [String] = []
/// for page in pages {
///     let result = try await service.analyzeKnittingPatternPage(...)
///     pageResults.append(resultString)
/// }
/// let final = try await service.consolidatePageResults(pageResults: pageResults, ...)
/// ----------------------------------------------------

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
    func analyzeKnittingPattern(fileData: Data, fileName: String = "") async throws -> KnittingAnalysis {
        let prompt = """
        업로드된 뜨개질 도안 파일을 분석해서 다음 정보를 JSON 형태로 정확하게 제공해주세요:

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
        
        let response = try await sendMessage(fileData: fileData, fileName: fileName, prompt: prompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    // MARK: - 2단계 분석 시스템
    
    /// 1단계: 페이지별 분석 (맥락 정보 포함)
    ///
    /// 앱에서 PDF 각 페이지를 이미지로 변환 후, 각 페이지를 본 함수로 개별 호출하여 부분 분석 결과를 얻음.
    /// 이때 파트 이름에 반드시 "(페이지 \(pageNumber))" 표시를 추가하여 어떤 페이지 결과인지 명확히 표기.
    /// 부분 정보나 불완전한 정보여도 무관하며, 전체가 아닌 부분만 있어도 빈 배열(parts: []) 로 응답 가능.
    ///
    /// 이후 2단계에서 이 페이지별 결과들을 모아 중복을 제거하고 병합하여 전체 뜨개질 도안 분석 결과를 생성함.
    ///
    /// 실제 사용 예시:
    /// ----------------------------------------------------
    /// var pageResults: [String] = []
    /// for page in 1...totalPages {
    ///     let result = try await service.analyzeKnittingPatternPage(
    ///         fileData: pageImageData,
    ///         fileName: "page_\(page).png",
    ///         pageNumber: page,
    ///         totalPages: totalPages
    ///     )
    ///     // 결과는 JSON 문자열 형태
    ///     pageResults.append(resultString)
    /// }
    /// ----------------------------------------------------
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
        6. 'row' 값은 반드시 Int(정수) 한 개만 넣으세요. 만약 '34~37단', '50~51단'처럼 범위로 표기되어 있다면, 각 단을 별도의 객체로 나누어 각각 row: 34, row: 35, ..., row: 37처럼 모두 추가하세요. 숫자가 아닌 구간 표기/문자열 등은 절대 사용하지 마세요.

        JSON 형식으로 출력:
        {
            "projectName": "전체 프로젝트 추정 이름",
            "parts": [
                {
                    "partName": "파트이름 (페이지 \(pageNumber))",
                    "targetRow": 목표단수또는null,
                    "stitchGuide": [
                        {
                            "row": 단수또는null,
                            "targetStitch": 코수또는null
                        }
                    ]
                }
            ]
        }

        예시 입력:
        - "1~3단: 80코"
        - "5단: 75코"

        예시 출력(JSON):
        [
          {"row": 1, "targetStitch": 80},
          {"row": 2, "targetStitch": 80},
          {"row": 3, "targetStitch": 80},
          {"row": 5, "targetStitch": 75}
        ]
        
        주의: null 값도 허용하되, 가능한 한 구체적인 정보를 추출하세요.
        """
        
        let response = try await sendMessage(fileData: fileData, fileName: fileName, prompt: pagePrompt)
        return try parseKnittingAnalysis(from: response)
    }
    
    /// 2단계: 텍스트 기반 통합 분석
    ///
    /// 1단계에서 페이지별로 얻은 JSON 문자열 배열(pageResults)을 받아,
    /// 중복된 파트명(예: "뒷판 (페이지 3)", "뒷판 (페이지 7)")을 병합하고,
    /// (페이지 N) 표시는 삭제하여 통합된 파트명으로 정리함.
    ///
    /// stitchGuide 내 중복/정렬 처리 및 null 값 합리적 대체 포함,
    /// 불필요한 파트는 제거하여 프로젝트를 3~8개의 핵심 파트로 요약한다.
    ///
    /// 최종적으로 가장 의미 있고 구체적인 프로젝트명을 결정하여 JSON으로 반환.
    ///
    /// 실제 사용 예시:
    /// ----------------------------------------------------
    /// let finalResult = try await service.consolidatePageResults(
    ///     pageResults: pageResultsArray,
    ///     originalFileName: "project.pdf"
    /// )
    /// ----------------------------------------------------
    ///
    /// - Parameters:
    ///   - pageResults: analyzeKnittingPatternPage 함수에서 반환된 페이지별 JSON 문자열 배열
    ///   - originalFileName: 원본 PDF 파일명 (분석 힌트용)
    ///
    /// - Returns: 통합 분석된 KnittingAnalysis 객체
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
        3. stitchGuide 정렬 및 중복 제거
        4. "(페이지 X)" 표시 제거
        5. 핵심 파트만 선별 (불필요한 파트 제거)
        6. 프로젝트명을 가장 구체적이고 의미있는 이름으로 결정

        **품질 기준**:
        - 최종 파트는 3-8개 정도가 적절
        - 각 파트는 명확한 목적을 가져야 함
        - 중복 정보는 철저히 제거
        - null 값들을 합리적인 기본값으로 대체

        최종 JSON 출력:
        {
            "projectName": "최종 프로젝트명",
            "parts": [
                {
                    "partName": "통합된 파트명",
                    "targetRow": 목표단수,
                    "stitchGuide": [
                        {
                            "row": 단수,
                            "targetStitch": 코수
                        }
                    ]
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

