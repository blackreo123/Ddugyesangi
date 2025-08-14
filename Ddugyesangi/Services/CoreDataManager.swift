import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    // 싱글톤 패턴으로 Core Data 매니저 생성
    static let shared = CoreDataManager()
    
    // private init으로 외부에서 인스턴스 생성 방지
    private init() {}
    
    // Core Data 컨테이너 (데이터베이스)
    lazy var persistentContainer: NSPersistentContainer = {
        // "Ddugyesangi"는 .xcdatamodeld 파일 이름과 동일해야 함
        let container = NSPersistentContainer(name: "Ddugyesangi")
        
        // 데이터베이스 로드
        container.loadPersistentStores { _, error in
            if let error = error {
                // 에러 발생 시 앱 크래시 (개발 중에만 사용)
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    // Core Data 컨텍스트 (데이터 작업 공간)
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // 변경사항 저장
    func save() {
        if context.hasChanges {
            do {
                try context.save()
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
    func createPart(name: String, startRow: Int16, startStitch: Int16, project: Project) -> Part {
        let part = Part(context: context)
        part.id = UUID()
        part.name = name
        part.startRow = startRow
        part.startStitch = startStitch
        part.currentRow = startRow
        part.currentStitch = startStitch
        part.project = project // 관계 설정
        
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
    
    // 단수 업
    func incrementCurrentRow(of part: Part) {
        part.currentRow += 1
        save()
    }
    
    // 단수 다운
    func decrementCurrentRow(of part: Part) {
        part.currentRow -= 1
        save()
    }
    
    // 코수 업
    func incrementCurrentStitch(of part: Part) {
        part.currentStitch += 1
        save()
    }
    
    // 코수 다운
    func decrementCurrentStitch(of part: Part) {
        part.currentStitch -= 1
        save()
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
