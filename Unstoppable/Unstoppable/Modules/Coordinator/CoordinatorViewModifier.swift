import Combine
import SwiftUI

struct CoordinatorViewModifier: ViewModifier {
    private let coordinator = Coordinator.shared
    private let level: Int

    @State private var currentType: Coordinator.RouteType?
    @State private var sheetHeight: CGFloat?
    @State private var cancellable: AnyCancellable?

    init(level: Int = 0) {
        self.level = level
    }

    func body(content: Content) -> some View {
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
