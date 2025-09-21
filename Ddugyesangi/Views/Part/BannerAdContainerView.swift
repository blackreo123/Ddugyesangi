//
//  BannerAdContainerView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/09/21.
//

import SwiftUI

struct BannerAdContainerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let adService: AdService
    
    var body: some View {
        BannerAdView(adService: adService)
            .frame(height: 50)
            .background(themeManager.currentTheme.backgroundColor)
    }
}