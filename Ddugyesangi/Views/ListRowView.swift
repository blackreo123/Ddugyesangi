import SwiftUI

enum ViewModelType {
    case project(ProjectListViewModel)
    case part(PartListViewModel)
}

struct ListRowView: View {
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
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Menu {
                Button("이름 변경") {
                    showingEditSheet = true
                }
                Button("삭제", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingEditSheet) {
            switch viewModel {
            case .project(let projectListViewModel):
                ProjectEditView(project: project!, viewModel: projectListViewModel, isPresented: $showingEditSheet)
            case .part(let partListViewModel):
                // todo
                ProjectEditView(project: project!, viewModel: ProjectListViewModel(), isPresented: $showingEditSheet)
            }
        }
    }
}
