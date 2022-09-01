import ThemeKit
import UIKit
import ComponentKit

class InformationModule {
    static func afterClose(_ action: @escaping () -> ()) -> (UIViewController) -> () {
        { controller in
            controller.dismiss(animated: true) {
                action()
            }
        }
    }

    static func simpleInfo(title: String, image: UIImage?, description: String, buttonTitle: String, onTapButton: ((UIViewController) -> ())?, onDismiss: (() -> ())? = nil) -> UIViewController {
        let title = BottomSheetItem.ComplexTitleViewItem(title: title, image: image)
        let description = InformationModule.Item.description(text: description)
        let button = InformationModule.ButtonItem(style: .yellow, title: buttonTitle, action: onTapButton)

        return InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [button], onDismiss: onDismiss)
    }

    static func viewController(title: BottomSheetItem.Title, items: [Item], buttons: [ButtonItem], onDismiss: (() -> ())? = nil) -> UIViewController {
        let viewController = InformationViewController(title: title)
        viewController.set(items: items)
        viewController.set(buttons: buttons)
        viewController.onDismiss = onDismiss

        return viewController
    }

}

extension InformationModule {

    enum Item {
        case description(text: String)
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
