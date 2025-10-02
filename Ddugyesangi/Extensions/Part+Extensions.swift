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
    
    // MARK: - StitchGuide 관리
    
    /// AI 분석으로 생성된 단수별 코수 정보
    var stitchGuides: [StitchGuide] {
        get {
            guard isSmart,
                  let data = stitchGuideData,
                  let guides = try? JSONDecoder().decode([StitchGuide].self, from: data) else {
                return []
            }
            return guides
        }
        set {
            if isSmart {
                stitchGuideData = try? JSONEncoder().encode(newValue)
            }
        }
    }
    
    /// 특정 단수의 목표 코수 조회
    func getTargetStitch(for row: Int) -> Int {
        if isSmart {
            // AI 분석 결과: 단수별 코수 정보에서 찾기
            let guide = stitchGuides.first { $0.row == row }
            return guide?.targetStitch ?? getCurrentTargetStitch()
        } else {
            // 일반 등록: 고정된 targetStitch 사용
            return getCurrentTargetStitch()
        }
    }
    
    /// 현재 단수에 가장 가까운 목표 코수 조회
    func getCurrentTargetStitch() -> Int {
        if isSmart {
            // 현재 단수보다 작거나 같은 단수 중 가장 큰 값
            let currentRowGuides = stitchGuides.filter { $0.row <= currentRow }
            let closestGuide = currentRowGuides.max { $0.row < $1.row }
            return closestGuide?.targetStitch ?? Int(targetStitch)
        } else {
            return Int(targetStitch)
        }
    }
    
    /// 다음 단수의 목표 코수 미리보기
    func getNextTargetStitch() -> Int? {
        if isSmart {
            let nextRowGuides = stitchGuides.filter { $0.row > currentRow }
            let nextGuide = nextRowGuides.min { $0.row < $1.row }
            return nextGuide?.targetStitch
        } else {
            return Int(targetStitch)
        }
    }
    
    // MARK: - 편의 메서드
    
    /// Part가 AI로 생성되었는지 확인
    var isAIGenerated: Bool {
        return isSmart
    }
    
    /// 단수별 코수 정보가 있는지 확인
    var hasStitchGuide: Bool {
        return isSmart && !stitchGuides.isEmpty
    }
    
    /// 디버깅용 설명
    public override var debugDescription: String {
        if isSmart {
            return """
            🤖 AI Part: \(name ?? "Unknown")
            📊 단수: \(currentRow)/\(targetRow)
            🧶 현재 코수: \(currentStitch)/\(getCurrentTargetStitch())
            📋 가이드: \(stitchGuides.count)개 단수 정보
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
