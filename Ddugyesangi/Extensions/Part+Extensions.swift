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
    /// 디버깅용 설명
    public override var debugDescription: String {
        return """
            ✋ 일반 Part: \(name ?? "Unknown")  
            📊 단수: \(currentRow)/\(targetRow)
            🧶 코수: \(currentStitch)
            """
    }
}

