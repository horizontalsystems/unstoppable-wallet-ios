import UIKit
import ComponentKit
import SectionsTableView

class BottomSheetItem {
    enum Title {
        case simple(viewItem: SimpleTitleViewItem)
        case complex(viewItem: ComplexTitleViewItem)
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
        let title: String
        let image: UIImage?

        init(title: String, image: UIImage?) {
            self.title = title
            self.image = image
        }
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

    static func simpleRow(tableView: UITableView, viewItem: SimpleViewItem, rowIndex: Int, isLast: Bool, action: (() -> Void)? = nil) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: .hStack([
                .image24 { component in
                    if let imageUrl = viewItem.imageUrl {
                        component.isHidden = false
                        component.setImage(urlString: imageUrl, placeholder: nil)
                    } else {
                        component.isHidden = true
                    }
                },
                .text { component in
                    component.font = .body
                    component.textColor = viewItem.titleColor
                    component.text = viewItem.title
                },
                .image20 { component in
                    component.isHidden = !viewItem.selected
                    component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                },
            ]),
            tableView: tableView,
            id: "row_\(rowIndex)",
            hash: "\(viewItem.selected)",
            height: .heightCell48,
            autoDeselect: action != nil,
            bind: { cell in
                cell.set(backgroundStyle: .bordered, isFirst: rowIndex == 0, isLast: isLast)
            },
            action: action
        )
    }

    static func complexRow(tableView: UITableView, viewItem: ComplexViewItem, rowIndex: Int, isLast: Bool, action: (() -> Void)? = nil) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: .hStack([
                .vStack([
                    .text { component in
                        component.font = .body
                        component.textColor = viewItem.titleColor
                        component.text = viewItem.title
                    },
                    .text { component in
                        component.font = .subhead2
                        component.textColor = viewItem.subtitleColor
                        component.text = viewItem.subtitle
                        component.isHidden = viewItem.subtitle == nil
                    },
                ]),
                .image20 { component in
                    component.isHidden = !viewItem.selected
                    component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                },
            ]),
            tableView: tableView,
            id: "row_\(rowIndex)",
            hash: "\(viewItem.selected)",
            height: .heightCell48,
            autoDeselect: action != nil,
            bind: { cell in
                cell.set(backgroundStyle: .bordered, isFirst: rowIndex == 0, isLast: isLast)
            },
            action: action
        )
    }
}
