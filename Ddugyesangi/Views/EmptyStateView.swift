import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("표시할 내용이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    EmptyStateView()
} 