import UIKit
import ComponentKit
import ThemeKit
import SectionsTableView

struct SelectorModule {

    static func singleSelectorViewController(title: String, viewItems: [ViewItem], onSelect: @escaping (Int) -> ()) -> UIViewController {
        let viewController = SingleSelectorViewController(title: title, viewItems: viewItems, onSelect: onSelect)
        return ThemeNavigationController(rootViewController: viewController)
    }

    static func bottomSingleSelectorViewController(image: BottomSheetTitleView.Image? = nil, title: String, subtitle: String? = nil, viewItems: [ViewItem], onSelect: @escaping (Int) -> ()) -> UIViewController {
        let viewController = BottomSingleSelectorViewController(image: image, title: title, subtitle: subtitle, viewItems: viewItems, onSelect: onSelect)
        return viewController.toBottomSheet
    }

    static func multiSelectorViewController(title: String, viewItems: [ViewItem], onFinish: @escaping ([Int]) -> ()) -> UIViewController {
        let viewController = MultiSelectorViewController(title: title, viewItems: viewItems, onFinish: onFinish)
        return ThemeNavigationController(rootViewController: viewController)
    }

    static func bottomMultiSelectorViewController(config: MultiConfig, delegate: IBottomMultiSelectorDelegate) -> UIViewController {
        let viewController = BottomMultiSelectorViewController(config: config, delegate: delegate)
        return viewController.toBottomSheet
    }

}

extension SelectorModule {

    private static func row(viewItem: ViewItem, tableView: SectionsTableView, hash: String, accessoryElement: CellBuilderNew.CellElement, backgroundStyle: BaseThemeCell.BackgroundStyle, index: Int, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .imageElement(image: viewItem.image, size: .image32),
                    .vStackCentered([
                        .hStack([
                            .textElement(text: .body(viewItem.title, color: viewItem.titleColor), parameters: .highHugging),
                            .margin8,
                            .badge { component in
                                component.isHidden = viewItem.badge == nil
                                component.badgeView.set(style: .small)
                                component.badgeView.text = viewItem.badge
                            },
                            .margin0,
                            .text { _ in
                            }
                        ]),
                        .margin(1),
                        .textElement(text: viewItem.subtitle.map {
                            .subhead2($0)
                        }, parameters: .truncatingMiddle),
                    ]),
                    accessoryElement
                ]),
                tableView: tableView,
                id: "item_\(index)",
                hash: hash,
                height: viewItem.subtitle != nil ? .heightDoubleLineCell : (viewItem.image != nil ? .heightCell56 : .heightCell48),
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    static func row(viewItem: ViewItem, tableView: SectionsTableView, selected: Bool, backgroundStyle: BaseThemeCell.BackgroundStyle, index: Int, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        row(
                viewItem: viewItem,
                tableView: tableView,
                hash: "\(selected)",
                accessoryElement: .image20 { component in
                    component.imageView.isHidden = !selected
                    component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                },
                backgroundStyle: backgroundStyle,
                index: index,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    static func row(viewItem: ViewItem, tableView: SectionsTableView, isOn: Bool, backgroundStyle: BaseThemeCell.BackgroundStyle, index: Int, isFirst: Bool = false, isLast: Bool = false, onToggle: @escaping (Int, Bool) -> ()) -> RowProtocol {
        row(
                viewItem: viewItem,
                tableView: tableView,
                hash: "\(isOn)",
                accessoryElement: .switch { component in
                    component.switchView.isOn = isOn
                    component.onSwitch = { onToggle(index, $0) }
                },
                backgroundStyle: backgroundStyle,
                index: index,
                isFirst: isFirst,
                isLast: isLast
        )
    }

}

extension SelectorModule {

    struct MultiConfig {
        let image: BottomSheetTitleView.Image
        let title: String
        let description: String?
        let allowEmpty: Bool
        let viewItems: [ViewItem]
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
