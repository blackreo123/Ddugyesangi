import SwiftUI

struct ProjectListView: View {
    @StateObject private var viewModel = ProjectListViewModel()
    @State private var showingAddProject = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색 바
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
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
            .background(Color(.systemBackground))
            
            // 배너 광고 영역 (고정 위치)
            BannerAdView()
                .frame(height: 50)
                .background(Color(.systemGray6))
        }
        .navigationTitle("뜨개질")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddProject = true
                }) {
                    Image(systemName: "plus")
                }
            }
            
//            ToolbarItem(placement: .navigationBarLeading) {
//                Menu {
//                    Button("샘플 데이터 생성") {
//                        viewModel.createSampleData()
//                    }
//                    Button("모든 데이터 삭제", role: .destructive) {
//                        viewModel.clearAllData()
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                }
//            }
        }
        .sheet(isPresented: $showingAddProject) {
            ProjectAddView(viewModel: viewModel, isPresented: $showingAddProject)
        }
        .onAppear {
            viewModel.loadAds()
        }
    }
}

// 검색 바
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("뜨개질 검색", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
