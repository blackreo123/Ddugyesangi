import SwiftUI

enum ViewModelType {
    case project(ProjectListViewModel)
    case part(PartListViewModel)
}

struct ListRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let project: Project?
    let part: Part?
    let viewType: ListViewType
    let viewModel: ViewModelType
    let onDelete: () -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewType == .project ? project?.name ?? "이름 없음" : part?.name ?? "이름 없음" )
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.textColor)
            }
            
            Spacer()
            
            Menu {
                Button(viewType == .project ? "이름 변경" : "편집") {
                    showingEditSheet = true
                }
                Button("삭제", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(themeManager.currentTheme.accentColor)
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(12)
        .sheet(isPresented: $showingEditSheet) {
            switch viewModel {
            case .project(let projectListViewModel):
                if let project = project {
                    ProjectEditView(project: project, viewModel: projectListViewModel, isPresented: $showingEditSheet)
                        .presentationDetents([.fraction(0.25)])
                        
                }
            case .part(let partListViewModel):
                if let part = part {
                    PartEditView(part: part, viewModel: partListViewModel, isPresented: $showingEditSheet)
                        .environmentObject(themeManager)
                        .presentationBackground(themeManager.currentTheme.backgroundColor)
                }
            }
        }
    }
}
