//
//  KnittingAnalysis.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/02.
//

import Foundation

struct KnittingAnalysis: Codable, Equatable {
    let id: UUID
    let projectName: String
    let parts: [KnittingPart]
    
    static func == (lhs: KnittingAnalysis, rhs: KnittingAnalysis) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case projectName
        case parts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()  // 디코딩 시 새 UUID 생성
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.parts = try container.decode([KnittingPart].self, forKey: .parts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(parts, forKey: .parts)
    }
    
    init(projectName: String, parts: [KnittingPart]) {
        self.id = UUID()
        self.projectName = projectName
        self.parts = parts
    }
}

struct KnittingPart: Codable, Equatable {
    let partName: String
    let targetRow: Int?
}
