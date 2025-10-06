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
        part.isSmart = true
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
    
    // MARK: - 스마트 파트 관련 유틸리티
    
    /// 모든 AI 생성 파트 조회
    func fetchSmartParts() -> [Part] {
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.predicate = NSPredicate(format: "isSmart == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Part.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching smart parts: \(error)")
            return []
        }
    }
    
    /// 일반 파트만 조회
    func fetchRegularParts() -> [Part] {
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.predicate = NSPredicate(format: "isSmart == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Part.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching regular parts: \(error)")
            return []
        }
    }
    
    // MARK: - 디버깅 메서드
    
    /// AI 분석 파트들의 상태 출력
    func printSmartPartsStatus() {
        let smartParts = fetchSmartParts()
        print("🤖 AI 생성 파트 현황:")
        for part in smartParts {
            print(part.debugDescription)
        }
    }
}
