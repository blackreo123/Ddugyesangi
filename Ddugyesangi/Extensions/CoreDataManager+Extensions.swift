//
//  CoreDataManager+Extensions.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/03.
//

import Foundation
import CoreData

// CoreDataManager.swift에 추가할 메서드들

extension CoreDataManager {
    
    // MARK: - AI 분석 결과로 Part 생성
    
    /// AI 분석 결과로 스마트 파트 생성
    func createSmartPart(
        name: String,
        targetRow: Int16,
        project: Project
    ) -> Part {
        let part = Part(context: context)
        part.id = UUID()
        part.name = name
        part.targetRow = targetRow
        part.currentRow = 0
        part.currentStitch = 0
        part.project = project
        
        save()
        return part
    }
    
    // MARK: - AI 분석 결과로 프로젝트 생성
    
    /// AI 분석 결과로 전체 프로젝트 생성
    func createProjectFromAI(analysis: KnittingAnalysis) -> Project {
        let project = createProject(name: analysis.projectName)
        
        for knittingPart in analysis.parts {
            _ = createSmartPart(
                name: knittingPart.partName,
                targetRow: Int16(knittingPart.targetRow ?? 0),
                project: project
            )
        }
        
        return project
    }
}
