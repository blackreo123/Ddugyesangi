import SwiftUI

struct ListRowView: View {
    let project: Project?
    let part: Part?
    let viewModel: ProjectListViewModel
    let viewType: ListViewType
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
                    if viewType == .project {
                        viewModel.deleteProject(project!)
                    } else if viewType == .part {
//                        viewModel.deletePart(part!)
                    }
                    
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
            if viewType == .project {
                ProjectEditView(project: project!, viewModel: viewModel, isPresented: $showingEditSheet)
            } else if viewType == .part {
                
            }
        }
    }
}
