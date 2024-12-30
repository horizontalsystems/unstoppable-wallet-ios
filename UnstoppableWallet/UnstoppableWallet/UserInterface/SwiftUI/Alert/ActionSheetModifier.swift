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
    private let configuration: ActionSheetConfiguration
    private let ignoreSafeArea: Bool

    @State private var bottomSheetViewController: UIViewController?

    init(item: Binding<Item?>,
         configuration: ActionSheetConfiguration = ActionSheetConfiguration(style: .sheet),
         ignoreSafeArea: Bool = false,
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
        self.ignoreSafeArea = ignoreSafeArea
        self.configuration = configuration
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
                ignoreSafeArea: ignoreSafeArea,
                focusFirstTextField: configuration.focusFirstTextField,
                isPresented: $isPresented
            ).toActionSheet(configuration: configuration)

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

    private let configuration: ActionSheetConfiguration
    private let ignoreSafeArea: Bool

    @State private var bottomSheetViewController: UIViewController?

    init(isPresented: Binding<Bool>,
         configuration: ActionSheetConfiguration = ActionSheetConfiguration(style: .sheet),
         ignoreSafeArea: Bool = false,
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder contentView: @escaping () -> ContentView)
    {
        _isPresented = isPresented
        self.configuration = configuration
        self.ignoreSafeArea = ignoreSafeArea
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
                focusFirstTextField: configuration.focusFirstTextField,
                isPresented: $isPresented
            ).toActionSheet(configuration: configuration)

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
        configuration: ActionSheetConfiguration = ActionSheetConfiguration(style: .sheet),
        ignoreSafeArea: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(
            BooleanActionSheetModifier(
                isPresented: isPresented,
                configuration: configuration,
                ignoreSafeArea: ignoreSafeArea,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }

    func bottomSheet<Item>(
        item: Binding<Item?>,
        configuration: ActionSheetConfiguration = ActionSheetConfiguration(style: .sheet),
        ignoreSafeArea: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View where Item: Identifiable {
        modifier(
            ActionSheetModifier(
                item: item,
                configuration: configuration,
                ignoreSafeArea: ignoreSafeArea,
                onDismiss: onDismiss,
                contentView: content
            )
        )
    }
}

class ActionSheetWrapperViewController: UIViewController {
    private let contentView: UIView
    private let ignoreSafeArea: Bool
    private let focusFirstTextField: Bool
    @Binding private var isPresented: Bool

    init(contentView: UIView, ignoreSafeArea: Bool = true, focusFirstTextField: Bool = false, isPresented: Binding<Bool>) {
        self.contentView = contentView
        self.ignoreSafeArea = ignoreSafeArea
        self.focusFirstTextField = focusFirstTextField
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
            if ignoreSafeArea {
                make.edges.equalToSuperview()
            } else {
                make.edges.equalTo(view.safeAreaLayoutGuide)
            }
        }

        contentView.backgroundColor = .clear
    }

    override func viewDidAppear(_: Bool) {
        if focusFirstTextField, let textField: UITextField = UIView.firstSubview(in: view) {
            textField.becomeFirstResponder()
        }
    }

    override var canBecomeFirstResponder: Bool {
        contentView.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        contentView.becomeFirstResponder()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false
    }
}
