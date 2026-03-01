//
//  DdugyesangiWidgetProvider.swift
//  DdugyesangiWidget
//

import WidgetKit
import SwiftUI

struct DdugyesangiWidgetEntry: TimelineEntry {
    let date: Date
    let partID: UUID?
    let partName: String
    let projectName: String
    let currentRow: Int16
    let targetRow: Int16
    let currentStitch: Int16
    let themeType: WidgetThemeType
    let isEmpty: Bool

    static var empty: DdugyesangiWidgetEntry {
        DdugyesangiWidgetEntry(
            date: Date(),
            partID: nil,
            partName: "",
            projectName: "",
            currentRow: 0,
            targetRow: 0,
            currentStitch: 0,
            themeType: .basic,
            isEmpty: true
        )
    }
}

struct DdugyesangiWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = DdugyesangiWidgetEntry
    typealias Intent = DdugyesangiWidgetConfigIntent

    func placeholder(in context: Context) -> Entry {
        DdugyesangiWidgetEntry(
            date: Date(),
            partID: UUID(),
            partName: NSLocalizedString("Part Name", comment: ""),
            projectName: NSLocalizedString("Project Name", comment: ""),
            currentRow: 42,
            targetRow: 100,
            currentStitch: 15,
            themeType: .basic,
            isEmpty: false
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = makeEntry(for: configuration)
        return Timeline(entries: [entry], policy: .never)
    }

    private func makeEntry(for configuration: Intent) -> Entry {
        let stack = SharedCoreDataStack.shared
        let part: WidgetPartData?

        if let selectedPart = configuration.selectedPart {
            part = stack.fetchPart(by: selectedPart.id)
        } else {
            part = stack.fetchMostRecentPart()
        }

        guard let part = part else {
            return .empty
        }

        let themeRaw = UserDefaults(suiteName: "group.com.jihayoon.ddugyesangi")?
            .string(forKey: "selectedTheme") ?? WidgetThemeType.basic.rawValue
        let themeType = WidgetThemeType(rawValue: themeRaw) ?? .basic

        return DdugyesangiWidgetEntry(
            date: Date(),
            partID: part.id,
            partName: part.name,
            projectName: part.projectName,
            currentRow: part.currentRow,
            targetRow: part.targetRow,
            currentStitch: part.currentStitch,
            themeType: themeType,
            isEmpty: false
        )
    }
}
