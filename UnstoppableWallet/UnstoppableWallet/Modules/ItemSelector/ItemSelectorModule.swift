import ThemeKit
import UIKit
import ComponentKit

class ItemSelectorModule {

    static func viewController(title: BottomSheetItem.Title, items: [Item], onTap: ((ItemSelectorViewController, Int) -> ())?) -> UIViewController {
        let viewController = ItemSelectorViewController(title: title, onTap: onTap)
        viewController.set(items: items)

        return viewController
    }

}

extension ItemSelectorModule {

    enum Item {
        case description(text: String)
        case simple(viewItem: BottomSheetItem.SimpleViewItem)
        case complex(viewItem: BottomSheetItem.ComplexViewItem)
    }

}
