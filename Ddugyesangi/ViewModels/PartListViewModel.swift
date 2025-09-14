//
//  PartListViewModel.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/27.
//

import Foundation

class PartListViewModel: ObservableObject {
    @Published var partList: [Part] = []
    @Published var adService = AdService.shared
    
    private let project: Project
    private let coreDataManager = CoreDataManager.shared
    
    init(project: Project) {
        self.project = project
        loadPartList(project: project)
    }
    
    private func loadPartList(project: Project) {
        partList = coreDataManager.fetchParts(for: project)
    }
    
    func createPart(name: String, startRow: Int16, targetRow: Int16, project: Project) {
        _ = coreDataManager.createPart(name: name, startRow: startRow, targetRow: targetRow, project: self.project)
        loadPartList(project: project)
    }
    
    func updatePart(part: Part, name: String, startRow: Int16, targetRow: Int16) {
        coreDataManager.updatePart(part, name: name, startRow: startRow, targetRow: targetRow)
        loadPartList(project: project)
    }
    
    func deletePart(part: Part) {
        coreDataManager.deletePart(part)
        loadPartList(project: project)
    }
    
    var partListIsEmpty: Bool {
        return partList.isEmpty
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
}
