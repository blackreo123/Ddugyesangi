//
//  PartEntity.swift
//  DdugyesangiWidget
//

import AppIntents
import Foundation

/// 위젯 설정 화면에서 파트를 선택할 수 있게 하는 AppEntity
struct PartAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Part")

    static var defaultQuery = PartEntityQuery()

    var id: UUID
    var name: String
    var projectName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(projectName)")
    }
}

struct PartEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [PartAppEntity] {
        let stack = SharedCoreDataStack.shared
        return identifiers.compactMap { id in
            guard let part = stack.fetchPart(by: id) else { return nil }
            return PartAppEntity(
                id: part.id,
                name: part.name,
                projectName: part.projectName
            )
        }
    }

    func suggestedEntities() async throws -> [PartAppEntity] {
        SharedCoreDataStack.shared.fetchAllParts().map { part in
            PartAppEntity(
                id: part.id,
                name: part.name,
                projectName: part.projectName
            )
        }
    }

    func defaultResult() async -> PartAppEntity? {
        guard let part = SharedCoreDataStack.shared.fetchMostRecentPart() else { return nil }
        return PartAppEntity(
            id: part.id,
            name: part.name,
            projectName: part.projectName
        )
    }
}
