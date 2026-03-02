import CoreData
import Foundation
import WidgetKit

class CoreDataManager: ObservableObject {
    // 싱글톤 패턴으로 Core Data 매니저 생성
    static let shared = CoreDataManager()

    static let appGroupIdentifier = "group.com.jihayoon.ddugyesangi"

    // private init으로 외부에서 인스턴스 생성 방지
    private init() {
        migrateStoreIfNeeded()
    }

    // App Group 공유 컨테이너 URL (App Group 미설정 시 nil)
    private static var sharedStoreURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("Ddugyesangi.sqlite")
    }

    // 기존 기본 스토어 URL
    private static var defaultStoreURL: URL {
        NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("Ddugyesangi.sqlite")
    }

    // 실제 사용할 스토어 URL (App Group 가능하면 공유, 아니면 기본)
    private static var activeStoreURL: URL {
        sharedStoreURL ?? defaultStoreURL
    }

    private static let migrationKey = "CoreDataMigratedToAppGroup"

    // 기존 스토어를 공유 컨테이너로 일회성 마이그레이션
    // 주의: persistentContainer에 접근하면 안 됨 (lazy 초기화로 빈 DB가 먼저 생성됨)
    private func migrateStoreIfNeeded() {
        // 이미 마이그레이션 완료
        if UserDefaults.standard.bool(forKey: Self.migrationKey) { return }

        guard let newURL = CoreDataManager.sharedStoreURL else { return }

        let fileManager = FileManager.default
        let oldURL = CoreDataManager.defaultStoreURL

        // 기존 스토어가 없으면 마이그레이션 불필요 (신규 설치)
        guard fileManager.fileExists(atPath: oldURL.path) else {
            UserDefaults.standard.set(true, forKey: Self.migrationKey)
            return
        }

        // 이전 실행에서 생성된 빈 공유 스토어가 있으면 삭제
        for suffix in ["", "-wal", "-shm"] {
            let file = newURL.deletingLastPathComponent()
                .appendingPathComponent(newURL.lastPathComponent + suffix)
            try? fileManager.removeItem(at: file)
        }

        guard let modelURL = Bundle.main.url(forResource: "Ddugyesangi", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            return
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            let options: [String: Any] = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            let oldStore = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType, configurationName: nil, at: oldURL, options: options
            )
            try coordinator.migratePersistentStore(
                oldStore, to: newURL, options: nil, withType: NSSQLiteStoreType
            )
            // 마이그레이션 성공 후 기존 파일 정리
            for suffix in ["", "-wal", "-shm"] {
                let file = oldURL.deletingLastPathComponent()
                    .appendingPathComponent(oldURL.lastPathComponent + suffix)
                try? fileManager.removeItem(at: file)
            }
            UserDefaults.standard.set(true, forKey: Self.migrationKey)
        } catch {
            print("Core Data migration failed: \(error)")
        }
    }

    // Core Data 컨테이너 (데이터베이스)
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Ddugyesangi")

        // App Group 공유 컨테이너 경로 설정 (없으면 기본 경로 사용)
        let description = NSPersistentStoreDescription(url: CoreDataManager.activeStoreURL)
        // 위젯 등 외부 프로세스의 변경 감지
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]

        // 데이터베이스 로드
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        // 위젯과 동시 쓰기 충돌 방지
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    /// 위젯 등 외부에서 변경한 데이터를 앱 컨텍스트에 반영
    func refreshFromStore() {
        context.stalenessInterval = 0
        context.refreshAllObjects()
    }
    
    // Core Data 컨텍스트 (데이터 작업 공간)
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // 변경사항 저장
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Error saving Core Data: \(error)")
            }
        }
    }
    
    // MARK: - Project CRUD Operations
    
    // 프로젝트 생성
    func createProject(name: String) -> Project {
        let project = Project(context: context)
        project.id = UUID()
        project.name = name
        
        save()
        return project
    }
    
    // 모든 프로젝트 조회
    func fetchProjects() -> [Project] {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        // 최신 순으로 정렬
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching projects: \(error)")
            return []
        }
    }
    
    // ID로 프로젝트 조회
    func fetchProject(by id: UUID) -> Project? {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Error fetching project: \(error)")
            return nil
        }
    }
    
    // 프로젝트 삭제
    func deleteProject(_ project: Project) {
        context.delete(project)
        save()
    }
    
    // MARK: - Part CRUD Operations
    
    // 파트 생성
    func createPart(name: String, targetRow: Int16, targetStitch: Int16 = 0, project: Project) -> Part {
        let part = Part(context: context)
        part.id = UUID()
        part.name = name
        part.targetRow = targetRow
        part.currentRow = 0
        part.currentStitch = 0
        part.lastModifiedAt = Date()
        part.project = project

        save()
        return part
    }
    
    // 모든 파트 조회
    func fetchParts() -> [Part] {
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Part.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching parts: \(error)")
            return []
        }
    }
    
    // 특정 프로젝트의 파트들 조회
    func fetchParts(for project: Project) -> [Part] {
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", project)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Part.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching parts: \(error)")
            return []
        }
    }
    
    // 파트 수정
    func updatePart(_ part: Part, name: String, targetRow: Int16) {
        part.name = name
        part.targetRow = targetRow
        save()
    }
    
    // 단수 업 (목표 단수 이상이면 무시)
    func incrementCurrentRow(of part: Part) {
        if part.targetRow > 0, part.currentRow >= part.targetRow { return }
        part.currentRow += 1
        part.lastModifiedAt = Date()
        save()
    }

    // 단수 다운
    func decrementCurrentRow(of part: Part) {
        part.currentRow -= 1
        part.lastModifiedAt = Date()
        save()
    }

    func updateCurrentRow(of part: Part, to value: Int16) {
        part.currentRow = value
        part.lastModifiedAt = Date()
        save()
    }

    // 코수 업
    func incrementCurrentStitch(of part: Part) {
        part.currentStitch += 1
        part.lastModifiedAt = Date()
        save()
    }

    // 코수 다운
    func decrementCurrentStitch(of part: Part) {
        part.currentStitch -= 1
        part.lastModifiedAt = Date()
        save()
    }

    func updateCurrentStitch(of part: Part, to value: Int16) {
        part.currentStitch = value
        part.lastModifiedAt = Date()
        save()
    }

    // 코수 리셋
    func resetCurrentStitch(of part: Part) {
        part.currentStitch = 0
        part.lastModifiedAt = Date()
        save()
    }
    
    // ID로 파트 조회
    func fetchPart(by id: UUID) -> Part? {
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching part: \(error)")
            return nil
        }
    }

    // 파트 삭제
    func deletePart(_ part: Part) {
        context.delete(part)
        save()
    }
    
    // MARK: - Utility Methods
    
    // 데이터베이스 초기화 (개발 중에만 사용)
    func clearAllData() {
        let projects = fetchProjects()
        let parts = fetchParts()
        
        for project in projects {
            context.delete(project)
        }
        
        for part in parts {
            context.delete(part)
        }
        
        save()
        print("🗑️ All data cleared")
    }
    
    // 데이터베이스 상태 확인
    func printDatabaseStatus() {
        let projects = fetchProjects()
        let parts = fetchParts()
        
        print("📊 Database Status:")
        print("   Projects: \(projects.count)")
        print("   Parts: \(parts.count)")
        
        for project in projects {
            print("   - Project: \(project.name ?? "Unknown")")
            if let projectParts = project.parts?.allObjects as? [Part] {
                print("     Parts: \(projectParts.count)")
            }
        }
    }
} 
