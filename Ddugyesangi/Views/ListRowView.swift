import SwiftUI

// 화면 타입을 정의하는 enum
enum ListViewType {
    case project
    case part
    case other
}

struct ListRowView: View {
    let project: Project
    let viewModel: ProjectListViewModel
    let viewType: ListViewType
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name ?? "이름 없음")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Menu {
                Button("이름 변경") {
                    showingEditSheet = true
                }
                Button("삭제", role: .destructive) {
                    viewModel.deleteProject(project)
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
            ProjectEditView(project: project, viewModel: viewModel, isPresented: $showingEditSheet)
        }
    }
}
