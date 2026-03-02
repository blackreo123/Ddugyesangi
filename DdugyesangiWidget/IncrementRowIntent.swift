//
//  IncrementRowIntent.swift
//  DdugyesangiWidget
//

import AppIntents
import WidgetKit

/// 위젯의 +1 버튼 인터랙티브 인텐트
struct IncrementRowIntent: AppIntent {
    static var title: LocalizedStringResource = "+1"

    @Parameter(title: "Part ID")
    var partID: String

    init() {}

    init(partID: UUID) {
        self.partID = partID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: partID) else {
            return .result()
        }
        SharedCoreDataStack.shared.incrementRow(for: uuid)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// 위젯의 -1 버튼 인터랙티브 인텐트
struct DecrementRowIntent: AppIntent {
    static var title: LocalizedStringResource = "-1"

    @Parameter(title: "Part ID")
    var partID: String

    init() {}

    init(partID: UUID) {
        self.partID = partID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: partID) else {
            return .result()
        }
        SharedCoreDataStack.shared.decrementRow(for: uuid)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
