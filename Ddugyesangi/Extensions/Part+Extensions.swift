//
//  Part+Extensions.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/02.
//

import Foundation
import CoreData

// MARK: - Part Entity Extensions
extension Part {
    // MARK: - 편의 메서드
    
    /// Part가 AI로 생성되었는지 확인
    var isAIGenerated: Bool {
        return isSmart
    }
    
    /// 디버깅용 설명
    public override var debugDescription: String {
        if isSmart {
            return """
            🤖 AI Part: \(name ?? "Unknown")
            📊 단수: \(currentRow)/\(targetRow)
            """
        } else {
            return """
            ✋ 일반 Part: \(name ?? "Unknown")  
            📊 단수: \(currentRow)/\(targetRow)
            🧶 코수: \(currentStitch)
            """
        }
    }
}

