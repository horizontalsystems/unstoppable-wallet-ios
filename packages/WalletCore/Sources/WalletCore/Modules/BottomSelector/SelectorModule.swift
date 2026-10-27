import UIKit

enum SelectorModule {}

extension SelectorModule {
    struct MultiConfig {
        let image: BottomSheetTitleView.Image
        let title: String
        let description: String?
        let allowEmpty: Bool
        let viewItems: [ViewItem]
        let footer: String?
    }

    struct ViewItem {
        let image: CellBuilderNew.CellElement.Image?
        let title: String
        let titleColor: UIColor
        let subtitle: String?
        let badge: String?
        let selected: Bool

        init(image: CellBuilderNew.CellElement.Image? = nil, title: String, titleColor: UIColor = .themeLeah, subtitle: String? = nil, badge: String? = nil, selected: Bool) {
            self.image = image
            self.title = title
            self.titleColor = titleColor
            self.subtitle = subtitle
            self.badge = badge
            self.selected = selected
        }
    }
}
