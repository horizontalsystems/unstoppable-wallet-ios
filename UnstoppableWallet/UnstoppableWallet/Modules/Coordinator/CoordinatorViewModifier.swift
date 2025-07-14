import SwiftUI

struct CoordinatorViewModifier: ViewModifier {
    @ObservedObject private var coordinator = Coordinator.shared
    private let level: Int

    @State private var sheetHeight: CGFloat = .zero

    init(level: Int = 0) {
        self.level = level
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding<Bool>(
                get: { coordinator.hasSheet(at: level) },
                set: { newValue in
                    if !newValue {
                        coordinator.onRouteDismissed(at: level)
                    }
                }
            )) {
                if let route = coordinator.route(at: level) {
                    route.content(isPresented: Binding<Bool>(
                        get: { coordinator.hasSheet(at: level) },
                        set: { newValue in
                            if !newValue {
                                coordinator.onRouteDismissed(at: level)
                            }
                        }
                    ))
                    .modifier(CoordinatorViewModifier(level: level + 1))
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { coordinator.hasBottomSheet(at: level) },
                set: { newValue in
                    if !newValue {
                        coordinator.onRouteDismissed(at: level)
                    }
                }
            )) {
                if let route = coordinator.route(at: level) {
                    ZStack {
                        Color.themeLawrence.ignoresSafeArea()

                        route.content(isPresented: Binding<Bool>(
                            get: { coordinator.hasBottomSheet(at: level) },
                            set: { newValue in
                                if !newValue {
                                    coordinator.onRouteDismissed(at: level)
                                }
                            }
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay {
                            GeometryReader { geometry in
                                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        }
                        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                            sheetHeight = newHeight
                        }
                    }
                    .presentationDetents([.height(sheetHeight)])
                    .modifier(CoordinatorViewModifier(level: level + 1))
                }
            }
            .transparentFullScreenCover(isPresented: Binding<Bool>(
                get: { coordinator.hasAlert(at: level) },
                set: { newValue in
                    if !newValue {
                        coordinator.onRouteDismissed(at: level)
                    }
                }
            )) {
                if let route = coordinator.route(at: level) {
                    route.content(isPresented: Binding<Bool>(
                        get: { coordinator.hasAlert(at: level) },
                        set: { newValue in
                            if !newValue {
                                coordinator.onRouteDismissed(at: level)
                            }
                        }
                    ))
                    .modifier(CoordinatorViewModifier(level: level + 1))
                }
            }
    }
}

extension Binding where Value: ExpressibleByNilLiteral {
    var isPresented: Binding<Bool> {
        Binding<Bool>(
            get: { self.wrappedValue != nil },
            set: { if !$0 { self.wrappedValue = nil } }
        )
    }
}
