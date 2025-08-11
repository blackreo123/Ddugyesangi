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
    @State private var showingAddProject = false
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
        .navigationTitle("뜨개질")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddProject) {
//            ProjectAddView(viewModel: viewModel, isPresented: $showingAddProject)
        }
        .onAppear {
//            viewModel.loadAds()
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
            ListRowView(project: project, part: part, viewType: .part, onDelete: {}, onEdit: {})
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
                showingAddProject = true
            }) {
                Image(systemName: "plus")
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button("샘플 데이터 생성") {
//                    viewModel.createSampleData()
                }
                Button("모든 데이터 삭제", role: .destructive) {
//                    viewModel.clearAllData()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}


