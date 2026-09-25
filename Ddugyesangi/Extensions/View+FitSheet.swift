//
//  View+FitSheet.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2026/09/25.
//

import SwiftUI

/// 시트 높이를 내용 높이에 맞추는 modifier
/// NavigationStack 안쪽 루트 컨텐츠에 적용하면 네비게이션 바 높이까지 포함해서 계산한다
private struct FitSheetToContentModifier: ViewModifier {
    @State private var sheetHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            // 키보드 등으로 가용 높이가 줄어도 측정값이 바뀌지 않도록 본래 높이로 고정
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height + proxy.safeAreaInsets.top
            } action: { height in
                sheetHeight = height
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents(detents)
    }

    private var detents: Set<PresentationDetent> {
        if let sheetHeight {
            return [.height(sheetHeight)]
        }
        return [.medium]
    }
}

extension View {
    func fitSheetToContent() -> some View {
        modifier(FitSheetToContentModifier())
    }
}
