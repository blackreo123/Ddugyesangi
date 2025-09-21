//
//  PartListView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/27.
//

import Foundation
import SwiftUI

struct PartListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel : PartListViewModel
    @State private var showingAddPart = false
    let project : Project

    init(project: Project) {
        self.project = project
        // StateObject 초기화
        self._viewModel = StateObject(wrappedValue: PartListViewModel(project: project))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            contentView
            bannerAdView
        }
        .navigationTitle(project.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddPart) {
            PartAddView(viewModel: viewModel, project: project, isPresented: $showingAddPart)
        }
        .onAppear {
            // onAppear에서 광고 로드
            viewModel.adService.loadBannerAd()
        }
    }
    
    // MARK: - Subviews
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.partListIsEmpty {
                    EmptyStateView()
                } else {
                    partListContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var partListContent: some View {
        ForEach(viewModel.partList, id: \.id) { part in
            NavigationLink(destination: PartDetailView(part: part)) {
                ListRowView(project: project,
                            part: part,
                            viewType: .part,
                            viewModel: .part(viewModel),
                            onDelete: { viewModel.deletePart(part: part) })
            }
        }
    }
    
    private var bannerAdView: some View {
        BannerAdContainerView(adService: viewModel.adService)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingAddPart = true
            }) {
                Image(systemName: "plus")
            }
        }
    }
}


