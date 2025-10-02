//
//  PartListViewModel.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/27.
//

import Foundation

class PartListViewModel: ObservableObject {
    @Published var partList: [Part] = []
    @Published var adService = AdService()
    
    private let project: Project
    private let coreDataManager = CoreDataManager.shared
    
    init(project: Project) {
        self.project = project
        loadPartList(project: project)
    }
    
    private func loadPartList(project: Project) {
        partList = coreDataManager.fetchParts(for: project)
    }
    
    func createPart(name: String, targetRow: Int16, project: Project) {
        _ = coreDataManager.createPart(name: name, targetRow: targetRow, project: self.project)
        loadPartList(project: project)
    }
    
    func updatePart(part: Part, name: String, targetRow: Int16) {
        coreDataManager.updatePart(part, name: name, targetRow: targetRow)
        loadPartList(project: project)
    }
    
    func deletePart(part: Part) {
        coreDataManager.deletePart(part)
        loadPartList(project: project)
    }
    
    var partListIsEmpty: Bool {
        return partList.isEmpty
    }
}
