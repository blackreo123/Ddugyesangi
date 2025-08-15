//
//  PartListView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/06/27.
//

import Foundation
import SwiftUI

struct PartListView: View {
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
            viewModel.loadAds()
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
        .background(Color(.systemBackground))
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
        BannerAdView()
            .frame(height: 50)
            .background(Color(.systemGray6))
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


