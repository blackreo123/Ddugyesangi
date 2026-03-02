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
    @State private var isMemoExpanded = false

    public var body: some View {
        VStack() {
            Spacer()
            HStack(spacing: 40) {
                Counter(part: part, viewModel: viewModel, type: .row)
                Counter(part: part, viewModel: viewModel, type: .stitch)
            }
            .navigationTitle(part.name ?? "")

            Spacer()

            if let memo = part.memo, !memo.isEmpty {
                memoView(memo: memo)
            }

            bannerAdView
        }
        .themedBackground()
        .onAppear {
            viewModel.adService.loadBannerAd()
        }
    }

    private func memoView(memo: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isMemoExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isMemoExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .animation(.easeInOut(duration: 0.3), value: isMemoExpanded)

                    Text(NSLocalizedString("memo", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Spacer()
                }
            }

            if isMemoExpanded {
                ScrollView {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var bannerAdView: some View {
        BannerAdContainerView(adService: viewModel.adService)
    }
}
