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

    func headerInfoRow(id: String, title: String, showInfo: Bool = false, topSeparator: Bool = true, action: (() -> ())? = nil) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(
                .text { (component: TextComponent) -> () in
                    component.font = .body
                    component.textColor = .themeLeah
                    component.text = title
                }
        )
        if showInfo {
            elements.append(.margin8)
            elements.append(
                    .image20 { (component: ImageComponent) -> () in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    }
            )
        }
        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: !topSeparator)
                },
                action: action
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
                    cell.label.text = text
                }
        )
    }

    func subtitleRow(text: String) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { (component: TextComponent) -> () in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = text
                    }
                ]),
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

    func titleValueArrowRow(id: String, title: Text?, value: Text? = nil, showArrow: Bool = true, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()
        if let title = title {
            elements.append(.text { (component: TextComponent) -> () in
                component.font = title.font
                component.textColor = title.textColor
                component.text = title.text
            })
        }
        if let value = value {
            elements.append(.text { (component: TextComponent) -> () in
                component.font = value.font
                component.textColor = value.textColor
                component.text = value.text
                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                component.setContentHuggingPriority(.required, for: .horizontal)
            })
        }
        if showArrow {
            elements.append(.margin8)
            elements.append(.image20 { (component: ImageComponent) -> () in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
            })
        }

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
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

    func imageTitleArrowRow(id: String, image: UIImage?, title: Text?, showArrow: Bool = true, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.image24 { (component: ImageComponent) -> () in
            component.imageView.image = image?.withTintColor(.themeGray)
        })
        if let title = title {
            elements.append(.text { (component: TextComponent) -> () in
                component.font = title.font
                component.textColor = title.textColor
                component.text = title.text
            })
        }
        if showArrow {
            elements.append(.margin8)
            elements.append(.image20 { (component: ImageComponent) -> () in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
            })
        }
        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    func imageTitleCheckRow(id: String, image: UIImage?, title: Text, selected: Bool = true, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        var elements: [CellBuilderNew.CellElement] = [
            .image24 { (component: ImageComponent) -> () in
                component.imageView.image = image
            },
            .text { (component: TextComponent) -> () in
                component.font = title.font
                component.textColor = title.textColor
                component.text = title.text
            }
        ]
        if selected {
            elements.append(.margin8)
            elements.append(.image20 { (component: ImageComponent) -> () in
                component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
            })
        }
        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
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

    func switchRow(id: String, title: String, isOn: Bool, isFirst: Bool = false, isLast: Bool = false, onSwitch: @escaping (Bool) -> (), onTap: (() -> ())? = nil) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    },
                    .switch { component in
                        component.switchView.isOn = isOn
                        component.onSwitch = onSwitch
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

}

extension SectionsTableView {

    struct Text {
        static func custom(_ text: String, _ font: UIFont, _ color: UIColor) -> Self { Text(text: text, font: font, textColor: color) }
        static func body(_ text: String, gray: Bool = false) -> Self { Text(text: text, font: .body, textColor: gray ? .themeGray: .themeLeah) }
        static func subhead1(_ text: String, gray: Bool = false) -> Self { Text(text: text, font: .subhead2, textColor: gray ? .themeGray: .themeLeah) }
        static func subhead2(_ text: String, gray: Bool = true) -> Self { Text(text: text, font: .subhead2, textColor: gray ? .themeGray: .themeLeah) }

        let text: String
        let font: UIFont
        let textColor: UIColor
    }

}


//CellBuilderNew.row(
//        rootElement: .hStack([
//            .image32 { (component: ImageComponent) in
//                component.setImage(urlString: logoUrl, placeholder: UIImage(named: "placeholder_circle_32"))
//            },
//            .text { (component: TextComponent) in
//                component.font = .body
//                component.textColor = .themeLeah
//                component.text = name
//            }
//        ]),
//        tableView: tableView,
//        id: "header-\(name)",
//        height: .heightCell48,
//        bind: { cell in
//            cell.set(backgroundStyle: .transparent)
//        }
//)
