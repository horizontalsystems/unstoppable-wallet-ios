import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

public class CellBuilder {
    public static let defaultMargin: CGFloat = .margin16
    public static let defaultLayoutMargins = UIEdgeInsets(top: 0, left: defaultMargin, bottom: 0, right: defaultMargin)

    public static func preparedCell(tableView: UITableView, indexPath: IndexPath, elements: [CellElement], layoutMargins: UIEdgeInsets = defaultLayoutMargins) -> UITableViewCell {
        let reuseIdentifier = reuseIdentifier(elements: elements, layoutMargins: layoutMargins)
        tableView.register(BaseThemeCell.self, forCellReuseIdentifier: reuseIdentifier)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        if let cell = cell as? BaseThemeCell {
            build(cell: cell, elements: elements, layoutMargins: layoutMargins)
        }
        return cell
    }

    public static func preparedSelectableCell(tableView: UITableView, indexPath: IndexPath, elements: [CellElement], layoutMargins: UIEdgeInsets = defaultLayoutMargins) -> UITableViewCell {
        let reuseIdentifier = selectableReuseIdentifier(elements: elements, layoutMargins: layoutMargins)
        tableView.register(BaseSelectableThemeCell.self, forCellReuseIdentifier: reuseIdentifier)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        if let cell = cell as? BaseThemeCell {
            build(cell: cell, elements: elements, layoutMargins: layoutMargins)
        }
        return cell
    }

    public static func row(
        elements: [CellElement],
        layoutMargins: UIEdgeInsets = defaultLayoutMargins,
        tableView: UITableView,
        id: String,
        hash: String? = nil,
        height: CGFloat? = nil,
        rowActionProvider: (() -> [RowAction])? = nil,
        dynamicHeight: ((CGFloat) -> CGFloat)? = nil,
        bind: ((BaseThemeCell) -> Void)? = nil
    ) -> RowProtocol {
        let reuseIdentifier = reuseIdentifier(elements: elements, layoutMargins: layoutMargins)

        tableView.register(BaseThemeCell.self, forCellReuseIdentifier: reuseIdentifier)

        return Row<BaseThemeCell>(
            id: id,
            hash: hash,
            height: height,
            rowActionProvider: rowActionProvider,
            rowType: .dynamic(reuseIdentifier: reuseIdentifier, prepare: { cell in
                guard let cell = cell as? BaseThemeCell else {
                    return
                }

                build(cell: cell, elements: elements, layoutMargins: layoutMargins)
            }),
            dynamicHeight: dynamicHeight,
            bind: { cell, _ in bind?(cell) }
        )
    }

    public static func selectableRow(
        elements: [CellElement],
        layoutMargins: UIEdgeInsets = defaultLayoutMargins,
        tableView: UITableView,
        id: String,
        hash: String? = nil,
        height: CGFloat? = nil,
        autoDeselect: Bool = false,
        rowActionProvider: (() -> [RowAction])? = nil,
        dynamicHeight: ((CGFloat) -> CGFloat)? = nil,
        bind: ((BaseThemeCell) -> Void)? = nil,
        action: (() -> Void)? = nil,
        actionWithCell: ((BaseThemeCell) -> Void)? = nil
    ) -> RowProtocol {
        let reuseIdentifier = selectableReuseIdentifier(elements: elements, layoutMargins: layoutMargins)

        tableView.register(BaseSelectableThemeCell.self, forCellReuseIdentifier: reuseIdentifier)

        return Row<BaseSelectableThemeCell>(
            id: id,
            hash: hash,
            height: height,
            autoDeselect: autoDeselect,
            rowActionProvider: rowActionProvider,
            rowType: .dynamic(reuseIdentifier: reuseIdentifier, prepare: { cell in
                guard let cell = cell as? BaseThemeCell else {
                    return
                }

                build(cell: cell, elements: elements, layoutMargins: layoutMargins)
            }),
            dynamicHeight: dynamicHeight,
            bind: { cell, _ in bind?(cell) },
            action: { cell in
                action?()
                actionWithCell?(cell)
            }
        )
    }

    public static func build(cell: BaseThemeCell, elements: [CellElement], layoutMargins: UIEdgeInsets = defaultLayoutMargins) {
        if cell.id != nil {
            return
        }

        var lastView: UIView?
        var lastMargin: CGFloat?

        for element in elements {
            switch element {
            case .margin0: lastMargin = 0
            case .margin4: lastMargin = .margin4
            case .margin8: lastMargin = .margin8
            case .margin12: lastMargin = .margin12
            case .margin16: lastMargin = .margin16
            case .margin24: lastMargin = .margin24
            default:
                if let view = view(element: element) {
                    if let last = lastMargin, let lastView {
                        cell.stackView.setCustomSpacing(last, after: lastView)
                        lastMargin = nil
                    }

                    cell.stackView.addArrangedSubview(view)
                    lastView = view
                }
            }
        }

        cell.stackView.spacing = defaultMargin
        cell.stackView.layoutMargins = layoutMargins
        cell.stackView.isLayoutMarginsRelativeArrangement = true

        cell.id = cellId(elements: elements, layoutMargins: layoutMargins)
    }

    public static func height(containerWidth: CGFloat, backgroundStyle: BaseThemeCell.BackgroundStyle, text: String, font: UIFont, verticalPadding: CGFloat = defaultMargin, elements: [LayoutElement]) -> CGFloat {
        var textWidth = containerWidth - BaseThemeCell.margin(backgroundStyle: backgroundStyle).width

        var lastMargin = defaultMargin

        for element in elements {
            switch element {
            case .margin0: lastMargin = 0
            case .margin4: lastMargin = .margin4
            case .margin8: lastMargin = .margin8
            case .margin12: lastMargin = .margin12
            case .margin16: lastMargin = .margin16
            case .margin24: lastMargin = .margin24
            case let .fixed(width):
                textWidth -= lastMargin + width
                lastMargin = defaultMargin
            case .multiline:
                textWidth -= lastMargin
                lastMargin = defaultMargin
            }
        }

        textWidth -= lastMargin

        return text.height(forContainerWidth: textWidth, font: font) + 2 * verticalPadding
    }

    private static func view(element: CellElement) -> UIView? {
        switch element {
        case .text: return TextComponent()
        case .multiText: return MultiTextComponent()
        case .image16: return ImageComponent(size: .iconSize16)
        case .image20: return ImageComponent(size: .iconSize20)
        case .image24: return ImageComponent(size: .iconSize24)
        case .image32: return ImageComponent(size: .iconSize32)
        case .transactionImage: return TransactionImageComponent()
        case .switch: return SwitchComponent()
        case .primaryButton: return PrimaryButtonComponent()
        case .primaryCircleButton: return PrimaryCircleButtonComponent()
        case .secondaryButton: return SecondaryButtonComponent()
        case .secondaryCircleButton: return SecondaryCircleButtonComponent()
        case .sliderButton: return SliderButtonComponent()
        case .badge: return BadgeComponent()
        case .spinner20: return SpinnerComponent(style: .small20)
        case .spinner24: return SpinnerComponent(style: .medium24)
        case .spinner48: return SpinnerComponent(style: .large48)
        case .determiniteSpinner20: return DeterminiteSpinnerComponent(size: .iconSize20)
        case .determiniteSpinner24: return DeterminiteSpinnerComponent(size: .iconSize24)
        case .determiniteSpinner48: return DeterminiteSpinnerComponent(size: .iconSize48)
        default: return nil
        }
    }

    private static func reuseIdentifier(elements: [CellElement], layoutMargins: UIEdgeInsets = defaultLayoutMargins) -> String {
        "\(BaseThemeCell.self)|\(cellId(elements: elements, layoutMargins: layoutMargins))"
    }

    private static func selectableReuseIdentifier(elements: [CellElement], layoutMargins: UIEdgeInsets = defaultLayoutMargins) -> String {
        "\(BaseSelectableThemeCell.self)|\(cellId(elements: elements, layoutMargins: layoutMargins))"
    }

    private static func cellId(elements: [CellElement], layoutMargins: UIEdgeInsets) -> String {
        "\(elements.map(\.rawValue).joined(separator: "-"))|\(Int(layoutMargins.top))-\(Int(layoutMargins.left))-\(Int(layoutMargins.bottom))-\(Int(layoutMargins.right))"
    }
}

public extension CellBuilder {
    enum CellElement: String {
        case text
        case multiText
        case image16
        case image20
        case image24
        case image32
        case transactionImage
        case `switch`
        case primaryButton
        case primaryCircleButton
        case secondaryButton
        case secondaryCircleButton
        case sliderButton
        case badge
        case spinner20
        case spinner24
        case spinner48
        case determiniteSpinner20
        case determiniteSpinner24
        case determiniteSpinner48

        case margin0
        case margin4
        case margin8
        case margin12
        case margin16
        case margin24
    }

    enum LayoutElement {
        case fixed(width: CGFloat)
        case multiline

        case margin0
        case margin4
        case margin8
        case margin12
        case margin16
        case margin24
    }
}
