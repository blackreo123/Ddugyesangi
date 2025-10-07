import Foundation
import CoreData

class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var searchText = ""
    
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        loadProjects()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProjectCreated),
            name: NSNotification.Name(NSNotification.Name(rawValue: "projectDidCreateFromAnalysis").rawValue),
            object: nil
        )
    }
    
    @objc private func handleProjectCreated() {
        loadProjects()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Core Data Operations
    
    // 프로젝트 목록 로드
    func loadProjects() {
        projects = coreDataManager.fetchProjects()
    }
    
    // 새 프로젝트 생성
    func createProject(name: String) {
        _ = coreDataManager.createProject(name: name)
        loadProjects() // 목록 새로고침
    }
    
    // 프로젝트 삭제
    func deleteProject(_ project: Project) {
        coreDataManager.deleteProject(project)
        loadProjects() // 목록 새로고침
    }
    
    // 프로젝트 업데이트
    func updateProject(_ project: Project, newName: String) {
        project.name = newName
        coreDataManager.save()
        loadProjects() // 목록 새로고침
    }
    
    // 검색된 프로젝트 필터링
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { project in
                project.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
} 
