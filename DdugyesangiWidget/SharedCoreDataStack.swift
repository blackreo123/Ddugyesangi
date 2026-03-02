//
//  SharedCoreDataStack.swift
//  DdugyesangiWidget
//

import CoreData
import Foundation

/// 위젯에서 사용하는 파트 데이터
struct WidgetPartData {
    let id: UUID
    let name: String
    let projectName: String
    let currentRow: Int16
    let targetRow: Int16
    let currentStitch: Int16
    let lastModifiedAt: Date?
}

/// 위젯 전용 경량 Core Data 스택 (App Group 공유 컨테이너 사용)
/// xcdatamodeld 없이 모델을 코드로 정의하여 위젯 번들에 모델 파일 불필요
final class SharedCoreDataStack {
    static let shared = SharedCoreDataStack()

    private static let appGroupIdentifier = "group.com.jihayoon.ddugyesangi"

    // MARK: - Core Data 모델 프로그래밍 방식 정의

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Part entity
        let partEntity = NSEntityDescription()
        partEntity.name = "Part"
        partEntity.managedObjectClassName = "NSManagedObject"

        let partID = NSAttributeDescription()
        partID.name = "id"
        partID.attributeType = .UUIDAttributeType
        partID.isOptional = true

        let partName = NSAttributeDescription()
        partName.name = "name"
        partName.attributeType = .stringAttributeType
        partName.isOptional = true

        let partCurrentRow = NSAttributeDescription()
        partCurrentRow.name = "currentRow"
        partCurrentRow.attributeType = .integer16AttributeType
        partCurrentRow.isOptional = true
        partCurrentRow.defaultValue = 0

        let partTargetRow = NSAttributeDescription()
        partTargetRow.name = "targetRow"
        partTargetRow.attributeType = .integer16AttributeType
        partTargetRow.isOptional = true
        partTargetRow.defaultValue = 0

        let partCurrentStitch = NSAttributeDescription()
        partCurrentStitch.name = "currentStitch"
        partCurrentStitch.attributeType = .integer16AttributeType
        partCurrentStitch.isOptional = true
        partCurrentStitch.defaultValue = 0

        let partCreatedAt = NSAttributeDescription()
        partCreatedAt.name = "createdAt"
        partCreatedAt.attributeType = .dateAttributeType
        partCreatedAt.isOptional = true

        let partLastModifiedAt = NSAttributeDescription()
        partLastModifiedAt.name = "lastModifiedAt"
        partLastModifiedAt.attributeType = .dateAttributeType
        partLastModifiedAt.isOptional = true

        let partMemo = NSAttributeDescription()
        partMemo.name = "memo"
        partMemo.attributeType = .stringAttributeType
        partMemo.isOptional = true

        // Project entity
        let projectEntity = NSEntityDescription()
        projectEntity.name = "Project"
        projectEntity.managedObjectClassName = "NSManagedObject"

        let projectID = NSAttributeDescription()
        projectID.name = "id"
        projectID.attributeType = .UUIDAttributeType
        projectID.isOptional = true

        let projectName = NSAttributeDescription()
        projectName.name = "name"
        projectName.attributeType = .stringAttributeType
        projectName.isOptional = true

        let projectCreatedAt = NSAttributeDescription()
        projectCreatedAt.name = "createdAt"
        projectCreatedAt.attributeType = .dateAttributeType
        projectCreatedAt.isOptional = true

        // Relationships
        let partToProject = NSRelationshipDescription()
        partToProject.name = "project"
        partToProject.destinationEntity = projectEntity
        partToProject.minCount = 0
        partToProject.maxCount = 1
        partToProject.deleteRule = .nullifyDeleteRule
        partToProject.isOptional = true

        let projectToParts = NSRelationshipDescription()
        projectToParts.name = "parts"
        projectToParts.destinationEntity = partEntity
        projectToParts.minCount = 0
        projectToParts.maxCount = 0 // to-many
        projectToParts.deleteRule = .cascadeDeleteRule
        projectToParts.isOptional = true

        partToProject.inverseRelationship = projectToParts
        projectToParts.inverseRelationship = partToProject

        partEntity.properties = [partID, partName, partCurrentRow, partTargetRow, partCurrentStitch, partCreatedAt, partLastModifiedAt, partMemo, partToProject]
        projectEntity.properties = [projectID, projectName, projectCreatedAt, projectToParts]

        model.entities = [partEntity, projectEntity]
        return model
    }

    private lazy var container: NSPersistentContainer = {
        let model = Self.createModel()
        let container = NSPersistentContainer(name: "Ddugyesangi", managedObjectModel: model)

        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
            let storeURL = groupURL.appendingPathComponent("Ddugyesangi.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.isReadOnly = false
            // 메인 앱의 컴파일된 모델과 version hash가 다를 수 있으므로 lightweight migration 허용
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget Core Data failed to load: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Fetch

    private func partData(from obj: NSManagedObject) -> WidgetPartData? {
        guard let id = obj.value(forKey: "id") as? UUID else { return nil }
        let project = obj.value(forKey: "project") as? NSManagedObject
        return WidgetPartData(
            id: id,
            name: obj.value(forKey: "name") as? String ?? "",
            projectName: project?.value(forKey: "name") as? String ?? "",
            currentRow: obj.value(forKey: "currentRow") as? Int16 ?? 0,
            targetRow: obj.value(forKey: "targetRow") as? Int16 ?? 0,
            currentStitch: obj.value(forKey: "currentStitch") as? Int16 ?? 0,
            lastModifiedAt: obj.value(forKey: "lastModifiedAt") as? Date
        )
    }

    /// 가장 최근 수정된 파트
    func fetchMostRecentPart() -> WidgetPartData? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Part")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModifiedAt", ascending: false)]
        request.fetchLimit = 1
        guard let obj = try? context.fetch(request).first else { return nil }
        return partData(from: obj)
    }

    /// ID로 파트 조회
    func fetchPart(by id: UUID) -> WidgetPartData? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Part")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let obj = try? context.fetch(request).first else { return nil }
        return partData(from: obj)
    }

    /// 전체 파트 목록 (최근 수정순)
    func fetchAllParts() -> [WidgetPartData] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Part")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModifiedAt", ascending: false)]
        return ((try? context.fetch(request)) ?? []).compactMap { partData(from: $0) }
    }

    // MARK: - Mutate

    /// 단수 -1 (0 이하이면 무시)
    func decrementRow(for partID: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Part")
        request.predicate = NSPredicate(format: "id == %@", partID as CVarArg)
        request.fetchLimit = 1
        guard let obj = try? context.fetch(request).first else { return }
        let current = obj.value(forKey: "currentRow") as? Int16 ?? 0
        if current <= 0 { return }
        obj.setValue(current - 1, forKey: "currentRow")
        obj.setValue(Date(), forKey: "lastModifiedAt")
        try? context.save()
    }

    /// 단수 +1 (목표 단수 이상이면 무시)
    func incrementRow(for partID: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Part")
        request.predicate = NSPredicate(format: "id == %@", partID as CVarArg)
        request.fetchLimit = 1
        guard let obj = try? context.fetch(request).first else { return }
        let current = obj.value(forKey: "currentRow") as? Int16 ?? 0
        let target = obj.value(forKey: "targetRow") as? Int16 ?? 0
        if target > 0, current >= target { return }
        obj.setValue(current + 1, forKey: "currentRow")
        obj.setValue(Date(), forKey: "lastModifiedAt")
        try? context.save()
    }
}
