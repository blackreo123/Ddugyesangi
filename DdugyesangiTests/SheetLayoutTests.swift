//
//  SheetLayoutTests.swift
//  DdugyesangiTests
//
//  Created by JIHA YOON on 2026/09/25.
//

import CoreData
import SwiftUI
import Testing
import UIKit
@testable import Ddugyesangi

/// 입력 시트(프로젝트/파트 추가·편집)가 내용 높이에 맞게 떠서
/// 네비게이션 바에 가리거나 시트 아래로 잘리는 입력 요소가 없는지 검증
@MainActor
@Suite(.serialized)
struct SheetLayoutTests {
    static let dynamicTypeSizes: [DynamicTypeSize] = [.large, .accessibility2]

    @Test("프로젝트 추가 시트가 내용에 맞게 뜬다", arguments: dynamicTypeSizes)
    func projectAddSheet(dynamicTypeSize: DynamicTypeSize) async throws {
        let viewModel = ProjectListViewModel()
        let layout = try await presentAndMeasure(dynamicTypeSize: dynamicTypeSize) { isPresented in
            ProjectAddView(viewModel: viewModel, isPresented: isPresented)
        }
        try expectFitsContent(layout, inputCount: 1)
    }

    @Test("프로젝트 편집 시트가 내용에 맞게 뜬다", arguments: dynamicTypeSizes)
    func projectEditSheet(dynamicTypeSize: DynamicTypeSize) async throws {
        let fixture = CoreDataFixture()
        defer { fixture.tearDown() }
        let viewModel = ProjectListViewModel()
        let layout = try await presentAndMeasure(dynamicTypeSize: dynamicTypeSize) { isPresented in
            ProjectEditView(project: fixture.project, viewModel: viewModel, isPresented: isPresented)
        }
        try expectFitsContent(layout, inputCount: 1)
    }

    @Test("파트 추가 시트가 내용에 맞게 뜬다", arguments: dynamicTypeSizes)
    func partAddSheet(dynamicTypeSize: DynamicTypeSize) async throws {
        let fixture = CoreDataFixture()
        defer { fixture.tearDown() }
        let viewModel = PartListViewModel(project: fixture.project)
        let layout = try await presentAndMeasure(dynamicTypeSize: dynamicTypeSize) { isPresented in
            PartAddView(viewModel: viewModel, project: fixture.project, isPresented: isPresented)
        }
        // 파트 이름, 목표 단수, 메모
        try expectFitsContent(layout, inputCount: 3)
    }

    @Test("파트 편집 시트가 내용에 맞게 뜬다", arguments: dynamicTypeSizes)
    func partEditSheet(dynamicTypeSize: DynamicTypeSize) async throws {
        let fixture = CoreDataFixture()
        defer { fixture.tearDown() }
        let viewModel = PartListViewModel(project: fixture.project)
        let layout = try await presentAndMeasure(dynamicTypeSize: dynamicTypeSize) { isPresented in
            PartEditView(part: fixture.part, viewModel: viewModel, isPresented: isPresented)
        }
        // 파트 이름, 목표 단수, 메모
        try expectFitsContent(layout, inputCount: 3)
    }

    // MARK: - Helpers

    /// 별도 윈도우에서 SwiftUI 시트를 띄우고 레이아웃이 안정되면 프레임을 측정
    private func presentAndMeasure<Content: View>(
        dynamicTypeSize: DynamicTypeSize,
        @ViewBuilder content: @escaping (Binding<Bool>) -> Content
    ) async throws -> SheetLayout {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1

        let themeManager = ThemeManager()
        let host = UIHostingController(rootView: SheetHost { isPresented in
            content(isPresented)
                .environmentObject(themeManager)
                .dynamicTypeSize(dynamicTypeSize)
        })
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            host.dismiss(animated: false)
            window.isHidden = true
        }

        // 표시 애니메이션과 높이 측정 후 detent 변경이 끝날 때까지 대기
        var stableLayout: SheetLayout?
        var previous: SheetLayout?
        var sameCount = 0
        let deadline = ContinuousClock.now + .seconds(5)
        while stableLayout == nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
            guard let sheet = host.presentedViewController, !sheet.isBeingPresented,
                  let layout = SheetLayout(sheetView: sheet.view, window: window) else { continue }
            sameCount = layout == previous ? sameCount + 1 : 0
            previous = layout
            if sameCount >= 3 {
                stableLayout = layout
            }
        }
        return try #require(stableLayout, "시트가 5초 안에 안정된 레이아웃으로 뜨지 않음")
    }

    private func expectFitsContent(
        _ layout: SheetLayout,
        inputCount: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        try #require(layout.inputs.count == inputCount, sourceLocation: sourceLocation)

        let tolerance: CGFloat = 1
        for input in layout.inputs {
            // 네비게이션 바(툴바) 뒤로 가리지 않아야 함
            #expect(input.minY >= layout.navigationBar.maxY - tolerance, "입력 요소가 네비게이션 바에 가림: \(input)", sourceLocation: sourceLocation)
            // 시트 아래로 잘리지 않아야 함
            #expect(input.maxY <= layout.sheet.maxY + tolerance, "입력 요소가 시트 밖으로 잘림: \(input)", sourceLocation: sourceLocation)
        }

        // 시트가 내용보다 과하게 크지 않아야 함 (하단 padding 16 + 홈 인디케이터 영역 + 여유 24)
        let lastInput = try #require(layout.inputs.last, sourceLocation: sourceLocation)
        let bottomGap = layout.sheet.maxY - lastInput.maxY
        #expect(bottomGap <= 16 + layout.bottomSafeArea + 24, "시트 하단에 빈 공간이 과함: \(bottomGap)pt", sourceLocation: sourceLocation)
    }
}

/// 테스트용 시트를 띄우는 호스트 뷰
private struct SheetHost<SheetContent: View>: View {
    @State private var isPresented = false
    let sheetContent: (Binding<Bool>) -> SheetContent

    var body: some View {
        Color.clear
            .onAppear { isPresented = true }
            .sheet(isPresented: $isPresented) {
                sheetContent($isPresented)
            }
    }
}

/// 윈도우 좌표계 기준 시트 레이아웃
private struct SheetLayout: Equatable {
    let sheet: CGRect
    let navigationBar: CGRect
    let inputs: [CGRect]
    let bottomSafeArea: CGFloat

    init?(sheetView: UIView, window: UIWindow) {
        guard let navigationBar = sheetView.firstDescendant(ofType: UINavigationBar.self) else { return nil }
        self.sheet = sheetView.convert(sheetView.bounds, to: window)
        self.navigationBar = navigationBar.convert(navigationBar.bounds, to: window)
        self.inputs = sheetView.textInputs
            .map { $0.convert($0.bounds, to: window) }
            .sorted { $0.minY < $1.minY }
        self.bottomSafeArea = window.safeAreaInsets.bottom
    }
}

/// 저장하지 않는 임시 Project/Part (테스트 후 컨텍스트에서 제거)
@MainActor
private struct CoreDataFixture {
    let context = CoreDataManager.shared.context
    let project: Project
    let part: Part

    init() {
        project = Project(context: context)
        project.id = UUID()
        project.name = "Sheet Layout Test"

        part = Part(context: context)
        part.id = UUID()
        part.name = "Sheet Layout Part"
        part.targetRow = 20
        part.memo = "memo"
        part.project = project
    }

    func tearDown() {
        context.delete(part)
        context.delete(project)
    }
}

private extension UIView {
    /// TextField(UITextField) / TextEditor(UITextView)로 렌더링된 입력 뷰
    var textInputs: [UIView] {
        subviews.flatMap { subview -> [UIView] in
            if subview.isHidden { return [] }
            if subview is UITextField || subview is UITextView { return [subview] }
            return subview.textInputs
        }
    }

    func firstDescendant<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews where !subview.isHidden {
            if let match = subview as? T { return match }
            if let match = subview.firstDescendant(ofType: type) { return match }
        }
        return nil
    }
}
