//
//  PartDetailView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

struct PartDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let part: Part
    @StateObject private var viewModel = PartDetailViewModel()
    
    public var body: some View {
        VStack() {
            Spacer()
            HStack(spacing: 40) {
                Counter(part: part, viewModel: viewModel, type: .row)
                Counter(part: part, viewModel: viewModel, type: .stitch)
            }
            .navigationTitle(part.name ?? "")
            
            Spacer()
            
//            bannerAdView
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onAppear {
            // onAppear에서 광고 로드
            viewModel.adService.loadBannerAd()
        }
    }
    
    private var bannerAdView: some View {
        BannerAdContainerView(adService: viewModel.adService)
    }
}
