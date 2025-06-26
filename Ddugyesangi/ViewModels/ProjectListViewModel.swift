import Foundation
import Combine
import CoreData

class ProjectListViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var adService = AdService.shared
    @Published var projects: [Project] = []
    @Published var searchText = ""
    
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadProjects()
    }
    
    private func setupBindings() {
        // AdService와의 바인딩 설정
        adService.$isAdLoaded
            .sink { [weak self] isLoaded in
                self?.isLoading = !isLoaded
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Core Data Operations
    
    // 프로젝트 목록 로드
    func loadProjects() {
        projects = coreDataManager.fetchProjects()
    }
    
    // 새 프로젝트 생성
    func createProject(name: String) {
        let newProject = coreDataManager.createProject(name: name)
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
    
    // MARK: - Ad Operations
    
    func loadAds() {
        adService.loadBannerAd()
    }
    
    func showInterstitialAd() {
        adService.showInterstitialAd()
    }
    
    func showRewardedAd() {
        adService.showRewardedAd()
    }
    
    // MARK: - Utility Methods
    
    // 샘플 데이터 생성 (개발용)
    func createSampleData() {
        let sampleNames = ["겨울 스웨터", "봄 가디건", "여름 베레모", "가을 목도리", "크리스마스 장갑"]
        
        for name in sampleNames {
            createProject(name: name)
        }
    }
    
    // 모든 데이터 삭제 (개발용)
    func clearAllData() {
        coreDataManager.clearAllData()
        loadProjects()
    }
} 
