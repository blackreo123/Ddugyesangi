//
//  DdugyesangiWidgetConfigIntent.swift
//  DdugyesangiWidget
//

import AppIntents
import WidgetKit

/// 위젯 설정 인텐트 — 사용자가 특정 파트를 선택하거나, nil이면 최근 수정 파트 자동 표시
struct DdugyesangiWidgetConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget_config_title"
    static var description: IntentDescription = "widget_config_description"

    @Parameter(title: "Part")
    var selectedPart: PartAppEntity?
}
