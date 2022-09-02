import UIKit
import ThemeKit
import ComponentKit

class InformationModule {
    static func afterClose(_ action: (() -> ())? = nil) -> (UIViewController) -> () {
        { controller in
            controller.dismiss(animated: true) {
                action?()
            }
        }
    }

    static func simpleInfo(title: String, image: UIImage?, description: String, buttonTitle: String, onTapButton: ((UIViewController) -> ())?, onInteractiveDismiss: (() -> ())? = nil) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: title, image: image)
        let description = InformationModule.Item.description(text: description, isHighlighted: true)
        let button = InformationModule.ButtonItem(style: .yellow, title: buttonTitle, action: onTapButton)

        return InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [button], onInteractiveDismiss: onInteractiveDismiss)
    }

    static func viewController(title: BottomSheetItem.Title, items: [Item] = [], buttons: [ButtonItem] = [], onInteractiveDismiss: (() -> ())? = nil) -> UIViewController {
        let viewController = InformationViewController(title: title)
        viewController.set(items: items)
        viewController.set(buttons: buttons)
        viewController.onInteractiveDismiss = onInteractiveDismiss

        return viewController.toBottomSheet
    }

}

extension InformationModule {

    static func copyConfirmation(value: String) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: "copy_warning.title".localized, image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob))
        let description = InformationModule.Item.description(text: "copy_warning.description".localized, isHighlighted: true)
        let copyButton = InformationModule.ButtonItem(style: .red, title: "copy_warning.i_will_risk_it".localized, action: InformationModule.afterClose {
            UIPasteboard.general.string = value
            HudHelper.instance.show(banner: .copied)
        })
        let dismissButton = InformationModule.ButtonItem(style: .transparent, title: "copy_warning.dont_copy".localized, action: InformationModule.afterClose())
        return InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [copyButton, dismissButton]).toBottomSheet
    }

    static func backupPrompt(action: (() -> ())?) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: "backup_prompt.title".localized, image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob))
        let description = InformationModule.Item.description(text: "backup_prompt.warning".localized, isHighlighted: true)
        let backupButton = InformationModule.ButtonItem(style: .yellow, title: "backup_prompt.backup".localized, action: InformationModule.afterClose(action))
        let laterButton = InformationModule.ButtonItem(style: .transparent, title: "backup_prompt.later".localized, action: InformationModule.afterClose())
        return InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [backupButton, laterButton]).toBottomSheet
    }

    static func description(title: String, text: String) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: title, image: UIImage(named: "circle_information_20")?.withTintColor(.themeGray))
        let description = InformationModule.Item.description(text: text, isHighlighted: false)
        return InformationModule.viewController(title: .complex(viewItem: title), items: [description, .margin(.margin8)]).toBottomSheet
    }

}

extension InformationModule {

    enum Item {
        case description(text: String, isHighlighted: Bool)
        case margin(_ height: CGFloat)
        case section(items: [SectionItem])
    }

    enum SectionItem {
        case simple(viewItem: BottomSheetItem.SimpleViewItem)
        case complex(viewItem: BottomSheetItem.ComplexViewItem)
    }

    struct ButtonItem {
        let style: PrimaryButton.Style
        let title: String
        let action: ((UIViewController) -> ())?
    }

    struct SimpleViewItem {
        let imageUrl: String?
        let title: String
        let titleColor: UIColor
        let selected: Bool

        init(imageUrl: String? = nil, title: String, titleColor: UIColor = .themeLeah, selected: Bool) {
            self.imageUrl = imageUrl
            self.title = title
            self.titleColor = titleColor
            self.selected = selected
        }
    }

    struct ComplexViewItem {
        let title: String
        let titleColor: UIColor
        let subtitle: String?
        let subtitleColor: UIColor
        let selected: Bool

        init(title: String, titleColor: UIColor = .themeLeah, subtitle: String? = nil, subtitleColor: UIColor = .themeGray, selected: Bool) {
            self.title = title
            self.titleColor = titleColor
            self.subtitle = subtitle
            self.subtitleColor = subtitleColor
            self.selected = selected
        }
    }

}
