//
//  DdugyesangiWidgetViews.swift
//  DdugyesangiWidget
//

import SwiftUI
import WidgetKit

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: DdugyesangiWidgetEntry

    private var theme: WidgetTheme {
        WidgetTheme.themes[entry.themeType] ?? WidgetTheme.themes[.basic]!
    }

    private var progress: Double {
        guard entry.targetRow > 0 else { return 0 }
        return min(Double(entry.currentRow) / Double(entry.targetRow), 1.0)
    }

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            contentView
        }
    }

    private var contentView: some View {
        VStack(spacing: 4) {
            Text(entry.partName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text("\(entry.currentRow)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryColor)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .invalidatableContent()

            if entry.targetRow > 0 {
                ProgressView(value: progress)
                    .tint(theme.primaryColor)
                Text("\(entry.currentRow)/\(entry.targetRow)")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryColor)
                    .contentTransition(.numericText())
            }

            Spacer()

            if let partID = entry.partID {
                HStack(spacing: 4) {
                    Button(intent: DecrementRowIntent(partID: partID)) {
                        Text("-1")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(theme.secondaryColor, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(intent: IncrementRowIntent(partID: partID)) {
                        Text("+1")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(theme.primaryColor, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .widgetURL(entry.partID.map { URL(string: "ddugyesangi://part/\($0.uuidString)")! })
        .containerBackground(for: .widget) {
            theme.backgroundColor
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("widget_empty", comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: DdugyesangiWidgetEntry

    private var theme: WidgetTheme {
        WidgetTheme.themes[entry.themeType] ?? WidgetTheme.themes[.basic]!
    }

    private var progress: Double {
        guard entry.targetRow > 0 else { return 0 }
        return min(Double(entry.currentRow) / Double(entry.targetRow), 1.0)
    }

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            contentView
        }
    }

    private var contentView: some View {
        GeometryReader { geo in
            let buttonWidth = geo.size.width / 3
            let infoWidth = geo.size.width - buttonWidth - 12

            HStack(spacing: 12) {
                // 왼쪽 2/3: 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.projectName)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryColor)
                        .lineLimit(1)

                    Text(entry.partName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("widget_row", comment: ""))
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryColor)
                        if entry.targetRow > 0 {
                            Text("\(entry.currentRow)/\(entry.targetRow)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.primaryColor)
                                .contentTransition(.numericText())
                                .invalidatableContent()
                        } else {
                            Text("\(entry.currentRow)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.primaryColor)
                                .contentTransition(.numericText())
                                .invalidatableContent()
                        }
                    }

                    if entry.targetRow > 0 {
                        ProgressView(value: progress)
                            .tint(theme.primaryColor)
                    }
                }
                .frame(width: infoWidth)

                // 오른쪽 1/3: +1, -1 버튼
                if let partID = entry.partID {
                    VStack(spacing: 4) {
                        Button(intent: IncrementRowIntent(partID: partID)) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("1")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .frame(width: buttonWidth, height: (geo.size.height - 4) / 2)
                            .background(theme.primaryColor, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button(intent: DecrementRowIntent(partID: partID)) {
                            HStack(spacing: 4) {
                                Image(systemName: "minus")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("1")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .frame(width: buttonWidth, height: (geo.size.height - 4) / 2)
                            .background(theme.secondaryColor, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .widgetURL(entry.partID.map { URL(string: "ddugyesangi://part/\($0.uuidString)")! })
        .containerBackground(for: .widget) {
            theme.backgroundColor
        }
    }

    private var emptyView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text(NSLocalizedString("widget_empty", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}
