import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var adService = AdService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // AdService와의 바인딩 설정
        adService.$isAdLoaded
            .sink { [weak self] isLoaded in
                self?.isLoading = !isLoaded
            }
            .store(in: &cancellables)
    }
    
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