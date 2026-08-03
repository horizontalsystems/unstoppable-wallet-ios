import Combine
import SwiftUI

public struct CoordinatorViewModifier: ViewModifier {
    private let coordinator = Coordinator.shared
    private let level: Int

    @State private var currentType: Coordinator.RouteType?
    @State private var sheetHeight: CGFloat?
    @State private var cancellable: AnyCancellable?

    public init(level: Int = 0) {
        self.level = level
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                currentType = coordinator.route(at: level)?.type
                cancellable = coordinator.publisher(for: level)
                    .sink { currentType = $0 }
            }
            .onDisappear {
                cancellable?.cancel()
                cancellable = nil
            }
            .sheet(isPresented: binding(for: .sheet)) {
                sheetContent()
            }
            .sheet(isPresented: binding(for: .bottomSheet)) {
                bottomSheetContent()
            }
            .transparentFullScreenCover(isPresented: binding(for: .alert)) {
                alertContent()
            }
    }

    private func binding(for type: Coordinator.RouteType) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                currentType == type
            },
            set: { newValue in
                if !newValue {
                    coordinator.onRouteDismissed(at: level)
                }
            }
        )
    }

    private func sheetContent() -> some View {
        Group {
            if let route = coordinator.route(at: level) {
                route.content(isPresented: binding(for: .sheet))
                    // Per-route identity: a new route at this level must be a NEW view, otherwise SwiftUI
                    // reuses the previous subtree and the presented screen's `@StateObject` (created once
                    // per identity) survives — showing the previously presented item's data.
                    .id(route.id)
                    .modifier(CoordinatorViewModifier(level: level + 1))
            }
        }
    }

    private func bottomSheetContent() -> some View {
        Group {
            if let route = coordinator.route(at: level) {
                ZStack {
                    Color.themeLawrence.ignoresSafeArea()

                    route.content(isPresented: binding(for: .bottomSheet))
                        .id(route.id)
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay {
                            GeometryReader { geometry in
                                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        }
                        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                            handleHeightChange(newHeight)
                        }
                }
                .presentationDetents([sheetHeight.map { .height($0) } ?? .medium])
                .modifier(CoordinatorViewModifier(level: level + 1))
            }
        }
    }

    private func alertContent() -> some View {
        Group {
            if let route = coordinator.route(at: level) {
                route.content(isPresented: binding(for: .alert))
                    .id(route.id)
                    .modifier(CoordinatorViewModifier(level: level + 1))
            }
        }
    }

    private func handleHeightChange(_ newHeight: CGFloat) {
        if sheetHeight != newHeight {
            sheetHeight = newHeight
        }
    }
}
