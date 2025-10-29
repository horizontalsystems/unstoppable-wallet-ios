
import Combine
import SectionsTableView
import SwiftUI
import UIKit

protocol IBottomSheetDismissDelegate: AnyObject {
    func bottomSelectorOnDismiss()
}

enum BottomSheetModule {
    static func viewController(image: BottomSheetTitleView.Image? = nil, title: String, subtitle: String? = nil, items: [Item] = [], buttons: [Button] = [], delegate: IBottomSheetDismissDelegate? = nil) -> UIViewController {
        let viewController = BottomSheetViewController(image: image, title: title, subtitle: subtitle, items: items, buttons: buttons, delegate: delegate)
        return viewController.toBottomSheet
    }
}

extension BottomSheetModule {
    static func copyConfirmation(value: String, onCopy: (() -> Void)? = nil) -> UIViewController {
        let wrapper = CopyConfirmationHostingController(value: value, onCopy: onCopy)
        return wrapper.toBottomSheet
    }

    static func description(title: String, text: String, buttons: [Button] = []) -> UIViewController {
        viewController(
            image: .local(name: "circle_information_20", tint: .gray),
            title: title,
            items: [
                .description(text: text),
            ],
            buttons: buttons
        )
    }

    static func cloudNotAvailableController() -> UIViewController {
        BottomSheetModule.viewController(
            image: .local(name: "icloud_24", tint: .warning),
            title: "backup.cloud.no_access.title".localized,
            items: [
                .highlightedDescription(text: "backup.cloud.no_access.description".localized),
            ],
            buttons: [
                .init(style: .yellow, title: "button.ok".localized, actionType: .afterClose),
            ]
        )
    }
}

extension BottomSheetModule {
    enum Item: Identifiable {
        case description(text: String)
        case highlightedDescription(text: String, style: HighlightedDescriptionBaseView.Style = .yellow)
        case copyableValue(title: String, value: String)
        case contractAddress(imageUrl: String, value: String, explorerUrl: String?)

        public var id: String {
            switch self {
            case let .description(text): return "description_\(text)"
            case let .highlightedDescription(text, style): return "highlightedDescription_\(text)_\(style.rawValue)"
            case let .copyableValue(title, value): return "copyableValue_\(title)_\(value)"
            case let .contractAddress(url, value, explorerUrl): return "contractAddress_\(url)_\(value)_\(explorerUrl ?? "N/A")"
            }
        }
    }

    struct Button: Identifiable {
        let style: PrimaryButton.Style
        let title: String
        let imageName: String?
        let actionType: ActionType
        let action: (() -> Void)?

        init(style: PrimaryButton.Style, title: String, imageName: String? = nil, actionType: ActionType = .regular, action: (() -> Void)? = nil) {
            self.style = style
            self.title = title
            self.imageName = imageName
            self.actionType = actionType
            self.action = action
        }

        enum ActionType {
            case regular
            case afterClose
        }

        public var id: String {
            "\(style.hashValue.description)_\(title)_\(imageName ?? "NA")"
        }
    }
}

struct ViewWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let viewController: UIViewController

    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

private class CopyConfirmationHostingController: UIHostingController<CopyConfirmationWrapperView> {
    init(value: String, onCopy: (() -> Void)?) {
        let isPresented = Binding<Bool>(
            get: { true },
            set: { _ in }
        )

        let view = CopyConfirmationWrapperView(
            value: value,
            onCopy: onCopy,
            isPresented: isPresented
        )

        super.init(rootView: view)

        let dismissBinding = Binding<Bool>(
            get: { true },
            set: { [weak self] newValue in
                if !newValue {
                    self?.dismiss(animated: true)
                }
            }
        )

        rootView = CopyConfirmationWrapperView(
            value: value,
            onCopy: onCopy,
            isPresented: dismissBinding
        )
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CopyConfirmationWrapperView: View {
    let value: String
    let onCopy: (() -> Void)?
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView.instance(
            icon: .error,
            title: "copy_warning.title".localized,
            items: [
                .text(text: "copy_warning.description".localized),
                .buttonGroup(
                    .init(buttons: [
                        .init(
                            style: .gray,
                            title: "copy_warning.i_will_risk_it".localized,
                            action: {
                                UIPasteboard.general.string = value
                                HudHelper.instance.show(banner: .copied)
                                onCopy?()
                                isPresented = false
                            }
                        ),
                        .init(
                            style: .transparent,
                            title: "copy_warning.dont_copy".localized,
                            action: {
                                isPresented = false
                            }
                        ),
                    ])
                ),
            ],
            isPresented: $isPresented
        )
    }
}
