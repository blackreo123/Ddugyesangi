//
//  PartDetailViewModel.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation

class PartDetailViewModel {
    @Published var adService = AdService.shared
    private let coreDataManager = CoreDataManager.shared
    
    
    // 단수 업
    func incrementCurrentRow(part: Part) {
        coreDataManager.incrementCurrentRow(of: part)
    }
    
    // 단수 다운
    func decrementCurrentRow(part: Part) {
        coreDataManager.decrementCurrentRow(of: part)
    }
    
    // 코수 업
    func incrementCurrentStitch(part: Part) {
        coreDataManager.incrementCurrentStitch(of: part)
    }
    
    // 코수 다운
    func decrementCurrentStitch(part: Part) {
        coreDataManager.decrementCurrentStitch(of: part)
    }
    
    // 코수 리셋
    func resetCurrentStitch(part: Part) {
        coreDataManager.resetCurrentStitch(of: part)
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
