import ComponentKit
import SectionsTableView
import SwiftUI
import ThemeKit
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
        viewController(
            image: .warning,
            title: "copy_warning.title".localized,
            items: [
                .highlightedDescription(text: "copy_warning.description".localized),
            ],
            buttons: [
                .init(style: .red, title: "copy_warning.i_will_risk_it".localized) {
                    UIPasteboard.general.string = value
                    HudHelper.instance.show(banner: .copied)
                    onCopy?()
                },
                .init(style: .transparent, title: "copy_warning.dont_copy".localized),
            ]
        )
    }

    static func backupPromptAfterCreate(account: Account, sourceViewController: UIViewController?) -> UIViewController {
        backupPrompt(
            title: "backup_prompt.backup_recovery_phrase".localized,
            description: "backup_prompt.warning".localized,
            cancelText: "backup_prompt.later".localized,
            account: account,
            sourceViewController: sourceViewController,
            statPage: .backupPromptAfterCreate
        )
    }

    static func backupRequiredPrompt(description: String, account: Account, sourceViewController: UIViewController?) -> UIViewController {
        backupPrompt(
            title: "backup_prompt.backup_required".localized,
            description: description,
            cancelText: "button.cancel".localized,
            account: account,
            sourceViewController: sourceViewController,
            statPage: .backupRequired
        )
    }

    private static func backupPrompt(title: String, description: String, cancelText: String, account: Account, sourceViewController: UIViewController?, statPage: StatPage) -> UIViewController {
        viewController(
            image: .warning,
            title: title,
            items: [
                .highlightedDescription(text: description),
            ],
            buttons: [
                .init(style: .yellow, title: "backup_prompt.backup_manual".localized, imageName: "edit_24", actionType: .afterClose) { [weak sourceViewController] in
                    guard let viewController = BackupModule.manualViewController(account: account) else {
                        return
                    }

                    sourceViewController?.present(viewController, animated: true)
                    stat(page: statPage, event: .open(page: .manualBackup))
                },
                .init(style: .gray, title: "backup_prompt.backup_cloud".localized, imageName: "icloud_24", actionType: .afterClose) { [weak sourceViewController] in
                    sourceViewController?.present(BackupModule.cloudViewController(account: account), animated: true)
                    stat(page: statPage, event: .open(page: .cloudBackup))
                },
                .init(style: .transparent, title: cancelText),
            ]
        )
    }

    static func description(title: String, text: String) -> UIViewController {
        viewController(
            image: .local(name: "circle_information_20", tint: .gray),
            title: title,
            items: [
                .description(text: text),
            ]
        )
    }

    static func confirmDeleteCloudBackupController(action: (() -> Void)?) -> UIViewController {
        viewController(
            image: .trash,
            title: "manage_account.cloud_delete_backup_recovery_phrase".localized,
            items: [
                .highlightedDescription(text: "manage_account.cloud_delete_backup_recovery_phrase.description".localized),
            ],
            buttons: [
                .init(style: .red, title: "button.delete".localized, actionType: .afterClose) {
                    action?()
                },
                .init(style: .transparent, title: "button.cancel".localized),
            ]
        )
    }

    static func deleteCloudBackupAfterManualBackupController(action: (() -> Void)?) -> UIViewController {
        viewController(
            image: .warning,
            title: "manage_account.manual_backup_required".localized,
            items: [
                .highlightedDescription(text: "manage_account.manual_backup_required.description".localized),
            ],
            buttons: [
                .init(style: .yellow, title: "manage_account.manual_backup_required.button".localized, actionType: .afterClose) {
                    action?()
                },
                .init(style: .transparent, title: "button.cancel".localized),
            ]
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
