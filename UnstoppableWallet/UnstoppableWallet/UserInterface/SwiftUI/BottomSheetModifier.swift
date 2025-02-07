import SwiftUI

struct BottomSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    private let item: Binding<Item?>
    private let contentView: (Item) -> ContentView

    @State private var sheetHeight: CGFloat = .zero

    init(item: Binding<Item?>, @ViewBuilder contentView: @escaping (Item) -> ContentView) {
        self.item = item
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: item) { item in
                ZStack {
                    Color.themeLawrence.ignoresSafeArea()

                    contentView(item)
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
            }
    }
}

struct BooleanBottomSheetModifier<ContentView: View>: ViewModifier {
    private let isPresented: Binding<Bool>
    private let contentView: () -> ContentView

    @State private var sheetHeight: CGFloat = .zero

    init(isPresented: Binding<Bool>, @ViewBuilder contentView: @escaping () -> ContentView) {
        self.isPresented = isPresented
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented) {
                ZStack {
                    Color.themeLawrence.ignoresSafeArea()

                    contentView()
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
            }
    }
}

extension View {
    func bottomSheetNew(isPresented: Binding<Bool>, @ViewBuilder contentView: @escaping () -> some View) -> some View {
        modifier(BooleanBottomSheetModifier(isPresented: isPresented, contentView: contentView))
    }

    func bottomSheetNew<Item>(item: Binding<Item?>, @ViewBuilder contentView: @escaping (Item) -> some View) -> some View where Item: Identifiable {
        modifier(BottomSheetModifier(item: item, contentView: contentView))
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
