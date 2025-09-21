//
//  PartDetailViewModel.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation

class PartDetailViewModel: ObservableObject {
    @Published var adService = AdService()
    private let coreDataManager = CoreDataManager.shared
    
    
    // 단수 업
    func incrementCurrentRow(part: Part) {
        coreDataManager.incrementCurrentRow(of: part)
    }
    
    // 단수 다운
    func decrementCurrentRow(part: Part) {
        coreDataManager.decrementCurrentRow(of: part)
    }
    
    // 단수 한번에 업다운
    func updateCurrentRow(part: Part, to newValue: Int16) {
        coreDataManager.updateCurrentRow(of: part, to: newValue)
    }
    
    // 코수 업
    func incrementCurrentStitch(part: Part) {
        coreDataManager.incrementCurrentStitch(of: part)
    }
    
    // 코수 다운
    func decrementCurrentStitch(part: Part) {
        coreDataManager.decrementCurrentStitch(of: part)
    }
    
    func updateCurrentStitch(part: Part, to newValue: Int16) {
        coreDataManager.updateCurrentStitch(of: part, to: newValue)
    }
    
    // 코수 리셋
    func resetCurrentStitch(part: Part) {
        coreDataManager.resetCurrentStitch(of: part)
    }
}
