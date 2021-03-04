import ThemeKit
import UIKit

class ItemSelectorModule {

    static func viewController(title: Title, items: [Item], onTap: ((ItemSelectorViewController, Int) -> ())?) -> UIViewController {
        let viewController = ItemSelectorViewController(title: title, onTap: onTap)
        viewController.set(items: items)

        return viewController
    }

}

extension ItemSelectorModule {

    enum Title {
        case simple(viewItem: SimpleTitleViewItem)
        case complex(viewItem: ComplexTitleViewItem)
    }

    enum Item {
        case description(text: String)
        case simple(viewItem: SimpleViewItem)
        case complex(viewItem: ComplexViewItem)
    }

    struct SimpleTitleViewItem {
        let title: String?
        let titleColor: UIColor

        init(title: String?, titleColor: UIColor = .themeGray) {
            self.title = title
            self.titleColor = titleColor
        }
    }

    struct ComplexTitleViewItem {
        let title: String?
        let titleColor: UIColor
        let subtitle: String?
        let subtitleColor: UIColor
        let image: UIImage?

        init(title: String?, titleColor: UIColor = .themeOz, subtitle: String?, subtitleColor: UIColor = .themeGray, image: UIImage?) {
            self.title = title
            self.titleColor = titleColor
            self.subtitle = subtitle
            self.subtitleColor = titleColor
            self.image = image
        }
    }

    struct SimpleViewItem {
        let title: String
        let titleColor: UIColor
        let selected: Bool

        init(title: String, titleColor: UIColor = .themeGray, selected: Bool) {
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

        init(title: String, titleColor: UIColor = .themeOz, subtitle: String? = nil, subtitleColor: UIColor = .themeGray, selected: Bool) {
            self.title = title
            self.titleColor = titleColor
            self.subtitle = subtitle
            self.subtitleColor = subtitleColor
            self.selected = selected
        }
    }

}
