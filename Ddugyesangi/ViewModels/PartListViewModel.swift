//
//  PartListViewModel.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/27.
//

import Foundation

class PartListViewModel: ObservableObject {
    @Published var partList: [Part] = []
    
    private let project: Project
    private let coreDataManager = CoreDataManager.shared
    
    init(project: Project) {
        self.project = project
        loadPartList(project: project)
    }
    
    private func loadPartList(project: Project) {
        partList = coreDataManager.fetchParts(for: project)
    }
    
    private func createPart(name: String, startRow: Int64, startStitch: Int64, project: Project) {
        _ = coreDataManager.createPart(name: name, startRow: startRow, startStitch: startStitch, project: self.project)
        loadPartList(project: project)
    }
    
    var partListIsEmpty: Bool {
        return partList.isEmpty
    }
}
