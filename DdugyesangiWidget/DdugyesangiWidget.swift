//
//  DdugyesangiWidget.swift
//  DdugyesangiWidget
//

import SwiftUI
import WidgetKit

struct DdugyesangiWidget: Widget {
    let kind: String = "DdugyesangiWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DdugyesangiWidgetConfigIntent.self,
            provider: DdugyesangiWidgetProvider()
        ) { entry in
            DdugyesangiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget_display_name", comment: ""))
        .description(NSLocalizedString("widget_description", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DdugyesangiWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DdugyesangiWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
