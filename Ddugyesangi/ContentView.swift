import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter

    var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            ProjectListView()
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .partList(let project):
                        PartListView(project: project)
                    case .partDetail(let part):
                        PartDetailView(part: part)
                    }
                }
        }
    }
}
