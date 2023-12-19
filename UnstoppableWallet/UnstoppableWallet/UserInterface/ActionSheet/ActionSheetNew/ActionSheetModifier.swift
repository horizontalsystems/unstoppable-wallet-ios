import Combine
import SnapKit
import SwiftUI
import ThemeKit
import UIKit

struct ActionSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    @Binding private var item: Item?
    @Binding private var isPresented: Bool

    private let onDismiss: (() -> Void)?
    private let contentView: (Item) -> ContentView

    @State private var bottomSheetViewController: UIViewController?

    init(item: Binding<Item?>,
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder contentView: @escaping (Item) -> ContentView)
    {
        _item = item
        _isPresented = Binding<Bool>(get: {
            item.wrappedValue != nil
        }, set: { _ in
            item.wrappedValue = nil
        })

        self.onDismiss = onDismiss
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content.onChange(of: item != nil, perform: updatePresentation)
    }

    private func updatePresentation(_: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else { return }

        guard let root = windowScene.keyWindow?.rootViewController else { return }

        var controllerToPresentFrom = root
        while let presented = controllerToPresentFrom.presentedViewController {
            controllerToPresentFrom = presented
        }

        if let item {
            let hostingViewController = UIHostingController(rootView: contentView(item))

            let bottomSheetViewController = ActionSheetWrapperViewController(
                contentView: hostingViewController.view,
                isPresented: $isPresented
            ).toBottomSheet

            self.bottomSheetViewController = bottomSheetViewController
            controllerToPresentFrom.present(bottomSheetViewController, animated: true)
        } else {
            onDismiss?()
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}

struct BooleanActionSheetModifier<ContentView: View>: ViewModifier {
    @Binding private var isPresented: Bool

    private let onDismiss: (() -> Void)?
    private let contentView: () -> ContentView

    @State private var bottomSheetViewController: UIViewController?

    init(isPresented: Binding<Bool>,
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder contentView: @escaping () -> ContentView)
    {
        _isPresented = isPresented
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
            let hostingViewController = UIHostingController(rootView: contentView())

            let bottomSheetViewController = ActionSheetWrapperViewController(
                contentView: hostingViewController.view,
                isPresented: $isPresented
            ).toBottomSheet

            self.bottomSheetViewController = bottomSheetViewController
            controllerToPresentFrom.present(bottomSheetViewController, animated: true)
        } else {
            onDismiss?()
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}

public extension View {
    func bottomSheet(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(
            BooleanActionSheetModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }

    func bottomSheet<Item>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View where Item: Identifiable {
        modifier(
            ActionSheetModifier(
                item: item,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }
}

class ActionSheetWrapperViewController: UIViewController {
    private let contentView: UIView
    @Binding private var isPresented: Bool

    init(contentView: UIView, isPresented: Binding<Bool>) {
        self.contentView = contentView
        _isPresented = isPresented

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeLawrence

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.backgroundColor = .clear
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false
    }
}
