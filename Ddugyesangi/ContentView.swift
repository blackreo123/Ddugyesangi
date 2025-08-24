import SwiftUI

struct ContentView: View {
    var body: some View {
        // TODO: navigationViewStyle이 사라질 예정이므로 다른 표현 방법을 찾기
        NavigationView {
            ProjectListView()
        }
        .navigationViewStyle(.stack)
    }
}
