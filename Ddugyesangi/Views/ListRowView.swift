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
                Text(viewType == .project ? project?.name ?? "No Name" : part?.name ?? "No Name")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.textColor)
            }
            
            Spacer()
            
            Menu {
                Button(viewType == .project ? "Name Change" : "Edit") {
                    showingEditSheet = true
                }
                Button("Delete", role: .destructive) {
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
                }
            }
        }
    }
}
