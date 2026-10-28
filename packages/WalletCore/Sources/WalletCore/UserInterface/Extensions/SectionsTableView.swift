
import SectionsTableView

import UIKit

extension SectionsTableView {
    func sectionFooter(text: String, textColor: UIColor = .themeGray, topMargin: CGFloat = .margin12, bottomMargin: CGFloat = .margin32) -> ViewState<BottomDescriptionHeaderFooterView> {
        registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        return .cellType(
            hash: text,
            binder: {
                $0.bind(text: text, textColor: textColor, topMargin: topMargin, bottomMargin: bottomMargin)
            },
            dynamicHeight: { BottomDescriptionHeaderFooterView.height(containerWidth: $0, text: text, topMargin: topMargin, bottomMargin: bottomMargin) }
        )
    }

    func highlightedDescriptionRow(id: String, style: HighlightedDescriptionBaseView.Style = .yellow, text: String, ignoreBottomMargin: Bool = false, topVerticalMargin: CGFloat? = nil) -> RowProtocol {
        registerCell(forClass: HighlightedDescriptionCell.self)

        return Row<HighlightedDescriptionCell>(
            id: id,
            dynamicHeight: { width in
                HighlightedDescriptionCell.height(containerWidth: width, text: text, ignoreBottomMargin: ignoreBottomMargin, topVerticalMargin: topVerticalMargin ?? HighlightedDescriptionCell.defaultVerticalMargin)
            },
            bind: { cell, _ in
                cell.set(style: style)
                cell.descriptionText = text
                if let topVerticalMargin {
                    cell.set(verticalMargin: topVerticalMargin)
                }
            }
        )
    }
}

extension SectionsTableView {
    // complete layout for more frequency used layouts

    // layout for standard cell with 24pt image
    func universalImage24Elements(image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.imageElement(image: image, size: .image24))
        if let title {
            elements.append(.textElement(text: title))
        }
        if let value {
            elements.append(.textElement(text: value, parameters: .allCompression))
        }
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(accessoryType))
        return elements
    }

    // layout for standard cell with 32pt image and optional double-line text
    func universalImage32Elements(image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, description: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.imageElement(image: image, size: .image32))

        if let title {
            var verticalTexts = [CellBuilderNew.CellElement]()
            verticalTexts.append(.textElement(text: title))
            if let description {
                verticalTexts.append(.margin(1))
                verticalTexts.append(.textElement(text: description))
            }

            elements.append(.vStackCentered(verticalTexts))
        }
        if let value {
            elements.append(.textElement(text: value, parameters: .allCompression))
        }
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(accessoryType))
        return elements
    }
}

extension SectionsTableView {
    // universal cell with image24, text, value and accessory for 48 height
    func universalRow48(id: String, image: CellBuilderNew.CellElement.Image? = nil, title: CellBuilderNew.CellElement.Text? = nil, value: CellBuilderNew.CellElement.Text? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none, hash: String? = nil, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: (() -> Void)? = nil) -> RowProtocol {
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
        action: (() -> Void)? = nil
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
