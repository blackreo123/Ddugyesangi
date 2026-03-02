import SwiftUI

enum AppDestination: Hashable {
    case partList(Project)
    case partDetail(Part)
}

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "ddugyesangi",
              url.host == "part",
              let uuidString = url.pathComponents.dropFirst().first,
              let uuid = UUID(uuidString: uuidString) else {
            return
        }

        guard let part = CoreDataManager.shared.fetchPart(by: uuid),
              let project = part.project else {
            return
        }

        // 기존 네비게이션 초기화 후 해당 파트로 이동
        path = NavigationPath()
        path.append(AppDestination.partList(project))
        path.append(AppDestination.partDetail(part))
    }
}
