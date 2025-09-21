import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = ProjectListViewModel()
    @State private var showingAddProject = false
    @State private var showingThemeSelector = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색 바
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .background(themeManager.currentTheme.backgroundColor)
            
            // 프로젝트 리스트 영역 (스크롤 가능)
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.filteredProjects.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(viewModel.filteredProjects, id: \.id) { project in
                            NavigationLink(destination: PartListView(project: project)) {
                                ListRowView(project: project,
                                            part: nil,
                                            viewType: .project,
                                            viewModel: .project(viewModel),
                                            onDelete: { viewModel.deleteProject(project) })
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .background(themeManager.currentTheme.backgroundColor)
            
            // 배너 광고 영역 (고정 위치)
            BannerAdView()
                .frame(height: 50)
                .background(themeManager.currentTheme.backgroundColor)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Project List")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddProject = true
                }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingThemeSelector = true
                }) {
                    Image(systemName: "paintpalette")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
                ProjectAddView(viewModel: viewModel, isPresented: $showingAddProject)
                .presentationDetents([.fraction(0.25)])
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelector(isPresented: $showingThemeSelector)
        }
        // ✅ onAppear에서 loadAds() 호출 제거 (BannerAdManager에서 자동 처리)
    }
}

// 검색 바
struct SearchBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var text: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                
                TextField("Search Projects", text: $text)
                    .foregroundStyle(themeManager.currentTheme.textColor)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 44)
    }
}
