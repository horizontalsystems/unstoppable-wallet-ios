import UIKit
import SectionsTableView
import ComponentKit
import ThemeKit

extension SectionsTableView {

    func sectionHeader(text: String, height: CGFloat? = nil, backgroundColor: UIColor = .clear) -> ViewState<SubtitleHeaderFooterView> {
        registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        return .cellType(
                hash: text,
                binder: { $0.bind(text: text, backgroundColor: backgroundColor) },
                dynamicHeight: { _ in height ?? SubtitleHeaderFooterView.height }
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
                }
        )
    }

    func subtitleWithInfoButtonRow(text: String, uppercase: Bool = true, action: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { (component: TextComponent) -> () in
                        component.font = .subhead1
                        component.textColor = .themeGray
                        component.text = uppercase ? text.uppercased() : text
                    },
                    .image20 { (component: ImageComponent) -> () in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    }
                ]),
                layoutMargins: UIEdgeInsets(top: 0, left: .margin32, bottom: 0, right: .margin32),
                tableView: self,
                id: "subtitle-\(text)",
                height: .margin32,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.selectionStyle = .none
                },
                action: action
        )
    }

}

extension SectionsTableView {
// complete layout for more frequency used layouts

    // layout for standard cell with 24pt image
    func universalImage24Elements(image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.imageElement(image: image, size: .image24))
        if let title = title {
            elements.append(.textElement(text: title))
        }
        if let value = value {
            elements.append(.textElement(text: value, parameters: .allCompression))
        }
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(accessoryType))
        return elements
    }

    // layout for standard cell with 32pt image and optional double-line text
    func universalImage32Elements(image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, description: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.imageElement(image: image, size: .image32))

        if let title = title {
            var verticalTexts = [CellBuilderNew.CellElement]()
            verticalTexts.append(.textElement(text: title))
            if let description = description {
                verticalTexts.append(.margin(1))
                verticalTexts.append(.textElement(text: description))
            }

            elements.append(.vStackCentered(verticalTexts))
        }
        if let value = value {
            elements.append(.textElement(text: value, parameters: .allCompression))
        }
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(accessoryType))
        return elements
    }

}

extension SectionsTableView {

    // universal cell with image24, text, value and accessory for 48 height
    func universalRow48(id: String, image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        let elements = universalImage24Elements(image: image, title: title, value: value, accessoryType: accessoryType)

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

    // universal cell with image32, text, value and accessory for 56 height
    func universalRow56(id: String, image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> ())? = nil) -> RowProtocol {
        let elements = universalImage32Elements(image: image, title: title, value: value, accessoryType: accessoryType)

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightCell56,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    // universal cell with image32, multi-text, value and accessory for 62 height
    func universalRow62(
            id: String,
            image: CellBuilderNew.CellElement.Image? = nil,
            title: CellBuilderNew.CellElement.Text? = nil,
            description: CellBuilderNew.CellElement.Text? = nil,
            value: CellBuilderNew.CellElement.Text? = nil,
            accessoryType: CellBuilderNew.CellElement.AccessoryType = .none,
            hash: String? = nil,
            backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence,
            autoDeselect: Bool = false,
            rowActionProvider: (() -> [RowAction])? = nil,
            isFirst: Bool = false,
            isLast: Bool = false,
            action: (() -> ())? = nil
    ) -> RowProtocol {
        let elements = universalImage32Elements(image: image, title: title, description: description, value: value, accessoryType: accessoryType)

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: self,
                id: id,
                hash: hash,
                height: .heightDoubleLineCell,
                autoDeselect: autoDeselect,
                rowActionProvider: rowActionProvider,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

}
