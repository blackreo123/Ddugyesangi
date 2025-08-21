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
    let viewModel: PartDetailViewModel = PartDetailViewModel()
    
    public var body: some View {
        VStack() {
            Spacer()
            HStack(spacing: 40) {
                VStack(spacing: 20) {
                    Counter(part: part, viewModel: viewModel, type: .row)
                    Text("Start Row") + Text(": \(part.startRow)")
                }
                VStack(spacing: 20) {
                    Counter(part: part, viewModel: viewModel, type: .stitch)
                    Text("Start Stitch") + Text(": \(part.startStitch)")
                }
            }
            .navigationTitle(part.name ?? "")
            
            Spacer()
            
            bannerAdView
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onAppear {
            viewModel.loadAds()
        }
    }
    
    private var bannerAdView: some View {
        BannerAdView()
            .frame(height: 50)
            .background(themeManager.currentTheme.backgroundColor)
    }
}
