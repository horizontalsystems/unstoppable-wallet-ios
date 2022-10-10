import UIKit
import SectionsTableView
import ComponentKit
import ThemeKit

extension SectionsTableView {

    func sectionHeader(text: String) -> ViewState<SubtitleHeaderFooterView> {
        registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        return .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    func sectionFooter(text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        return .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { BottomDescriptionHeaderFooterView.height(containerWidth: $0, text: text) }
        )
    }

    func highlightedDescriptionRow(id: String, text: String, ignoreBottomMargin: Bool = false) -> RowProtocol {
        registerCell(forClass: HighlightedDescriptionCell.self)

        return Row<HighlightedDescriptionCell>(
                id: id,
                dynamicHeight: { width in
                    HighlightedDescriptionCell.height(containerWidth: width, text: text, ignoreBottomMargin: ignoreBottomMargin)
                },
                bind: { cell, _ in
                    cell.descriptionText = text
                }
        )
    }

    func descriptionRow(id: String, text: String, ignoreBottomMargin: Bool = false) -> RowProtocol {
        registerCell(forClass: DescriptionCell.self)

        return Row<DescriptionCell>(
                id: id,
                dynamicHeight: { width in
                    DescriptionCell.height(containerWidth: width, text: text, ignoreBottomMargin: ignoreBottomMargin)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    func subtitleRow(text: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text],
                tableView: self,
                id: "subtitle_\(text)",
                hash: text,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = text
                    }
                }
        )
    }

    func titleArrowRow(id: String, title: String, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    }
                    cell.bind(index: 1) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: action
        )
    }

    func imageTitleRow(id: String, image: UIImage?, title: String, color: UIColor = .themeLeah, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image20 { component in
                        component.imageView.image = image?.withTintColor(color)
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = color
                        component.text = title
                    }
                ]),
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    func imageTitleArrowRow(id: String, image: UIImage?, title: String, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image20 { component in
                        component.imageView.image = image?.withTintColor(.themeGray)
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    },
                    .image20 { component in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                ]),
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    func imageTitleCheckRow(id: String, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, image: String, title: String, selected: Bool, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: self,
                id: id,
                hash: "\(selected)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: image)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.isHidden = !selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                },
                action: action
        )
    }

    func subtitleWithInfoButtonRow(text: String, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                layoutMargins: UIEdgeInsets(top: 0, left: .margin32, bottom: 0, right: .margin32),
                tableView: self,
                id: "subtitle-\(text)",
                height: .margin32,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.selectionStyle = .none

                    cell.bind(index: 0, block: { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = .themeGray
                        component.text = text.uppercased()
                    })

                    cell.bind(index: 1, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    })
                },
                action: action
        )
    }

    func grayTitleWithArrowRow(id: String, title: String, isFirst: Bool = false, isLast: Bool = false, onTap: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    },
                    .image20 { component in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                ]),
                tableView: self,
                id: id,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: onTap
        )
    }

    func grayTitleWithValueRow(id: String, hash: String? = nil, title: String, value: String, valueColor: UIColor = .themeLeah, isFirst: Bool = false, isLast: Bool = false) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    },
                    .text { component in
                        component.font = .subhead1
                        component.textColor = valueColor
                        component.text = value
                    }
                ]),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                }
        )
    }

}
