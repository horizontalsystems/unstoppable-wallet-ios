import Combine
import SwiftUI

struct ActionSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    @Binding private var item: Item?
    @Binding private var isPresented: Bool

    private var heightSubject = CurrentValueSubject<CGFloat, Never>(UIScreen.main.bounds.height)

    private let configuration: ActionSheetConfiguration
    private let onDismiss: (() -> Void)?
    private let contentView: (Item) -> ContentView

    @State private var bottomSheetViewController: ActionSheetControllerSwiftUI?

    init(item: Binding<Item?>,
         configuration: ActionSheetConfiguration = .init(style: .sheet),
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder contentView: @escaping (Item) -> ContentView)
    {
        _item = item
        self._isPresented = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { newValue in
            item.wrappedValue = nil
        })

        self.configuration = configuration
        self.onDismiss = onDismiss
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content.onChange(of: item != nil, perform: updatePresentation)
    }

    private func updatePresentation(_ isPresented: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else { return }

        guard let root = windowScene.keyWindow?.rootViewController else { return }

        var controllerToPresentFrom = root
        while let presented = controllerToPresentFrom.presentedViewController {
            controllerToPresentFrom = presented
        }

        if let item {
            let content = contentView(item)
                .overlay {
                    GeometryReader { proxy in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: proxy.size.height + proxy.safeAreaInsets.bottom)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) {
                    heightSubject.send($0)
                }

            let hostingViewController = UIHostingController(rootView: content)
            let bottomSheetViewController = ActionSheetControllerSwiftUI(
                isPresented: $isPresented,
                heightSubject: heightSubject,
                content: hostingViewController,
                configuration: ActionSheetConfiguration(style: .sheet)
            )

            self.bottomSheetViewController = bottomSheetViewController
            controllerToPresentFrom.present(bottomSheetViewController, animated: true)
        } else {
            onDismiss?()
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}

struct EmptyActionSheetModifier<ContentView: View>: ViewModifier {
    @Binding private var isPresented: Bool

    private var heightSubject = CurrentValueSubject<CGFloat, Never>(UIScreen.main.bounds.height)

    private let configuration: ActionSheetConfiguration
    private let onDismiss: (() -> Void)?
    private let contentView: () -> ContentView

    @State private var bottomSheetViewController: ActionSheetControllerSwiftUI?

    init(isPresented: Binding<Bool>,
         configuration: ActionSheetConfiguration = .init(style: .sheet),
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder contentView: @escaping () -> ContentView)
    {
        _isPresented = isPresented
        self.configuration = configuration
        self.onDismiss = onDismiss
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content.onChange(of: isPresented, perform: updatePresentation)
    }

    private func updatePresentation(_ isPresented: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else { return }

        guard let root = windowScene.keyWindow?.rootViewController else { return }

        var controllerToPresentFrom = root
        while let presented = controllerToPresentFrom.presentedViewController {
            controllerToPresentFrom = presented
        }

        if isPresented {
            let content = contentView()
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear.preference(key: InnerHeightPreferenceKey.self, value: proxy.size.height + proxy.safeAreaInsets.bottom)
                        }
                    }
                    .onPreferenceChange(InnerHeightPreferenceKey.self) {
                        heightSubject.send($0)
                    }

            let hostingViewController = UIHostingController(rootView: content)
            let bottomSheetViewController = ActionSheetControllerSwiftUI(
                    isPresented: $isPresented,
                    heightSubject: heightSubject,
                    content: hostingViewController,
                    configuration: ActionSheetConfiguration(style: .sheet)
            )

            self.bottomSheetViewController = bottomSheetViewController
            controllerToPresentFrom.present(bottomSheetViewController, animated: true)
        } else {
            onDismiss?()
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}

public extension View {
    func bottomSheet<Content>(
            isPresented: Binding<Bool>,
            configuration: ActionSheetConfiguration = .init(style: .sheet),
            onDismiss: (() -> Void)? = nil,
            @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {

        modifier(
            EmptyActionSheetModifier(
                isPresented: isPresented,
                configuration: configuration,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }

    func bottomSheet<Item, Content>(
            item: Binding<Item?>,
            configuration: ActionSheetConfiguration = .init(style: .sheet),
            onDismiss: (() -> Void)? = nil,
            @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item: Identifiable, Content: View {

        modifier(
            ActionSheetModifier(
                item: item,
                configuration: configuration,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
