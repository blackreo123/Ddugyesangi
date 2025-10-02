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
    private let baseURL = "https://api.anthropic.com/v1"
    private let anthropicVersion = "2023-06-01"  // 안정적인 버전 사용
    
    init(apiKey: String) {
        self.apiKey = apiKey
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
        
        let base64Image = imageData.base64EncodedString()
        
        let parameters: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",  // 검증된 모델 사용
            "max_tokens": 2000,
            "temperature": 0.1,  // 낮은 temperature로 일관된 결과
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
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: ClaudeResponse.self) { response in
                    switch response.result {
                    case .success(let claudeResponse):
                        let content = claudeResponse.content.first?.text ?? ""
                        continuation.resume(returning: content)
                    case .failure(let error):
                        print("❌ Claude API 에러: \(error)")
                        continuation.resume(throwing: ClaudeAPIError.networkError(error.localizedDescription))
                    }
                }
        }
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
