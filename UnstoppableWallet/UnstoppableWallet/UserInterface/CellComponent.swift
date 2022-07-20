import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit

struct CellComponent {

    static func actionTitleRow(tableView: UITableView, rowInfo: RowInfo, iconName: String?, iconDimmed: Bool, title: String, value: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .text],
                tableView: tableView,
                id: "action-\(rowInfo.index)",
                hash: "action-\(value)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        if let iconName = iconName {
                            component.isHidden = false
                            component.imageView.image = UIImage(named: iconName)?.withTintColor(iconDimmed ? .themeGray : .themeLeah)
                        } else {
                            component.isHidden = true
                        }
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = value
                    }
                }
        )
    }

    static func amountRow(tableView: UITableView, rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .text],
                tableView: tableView,
                id: "amount-\(rowInfo.index)",
                hash: "amount-\(coinAmount)-\(currencyAmount ?? "")",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: iconUrl, placeholder: UIImage(named: iconPlaceholderImageName))
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: type.textStyle)
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = coinAmount
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = currencyAmount
                    }
                }
        )
    }

    static func doubleAmountRow(tableView: UITableView, rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, primaryCoinAmount: String, primaryCurrencyAmount: String?, primaryType: AmountType, secondaryCoinAmount: String, secondaryCurrencyAmount: String?, secondaryType: AmountType) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .multiText, .multiText],
                tableView: tableView,
                id: "double-amount-\(rowInfo.index)",
                hash: "double-amount-\(primaryCoinAmount)-\(primaryCurrencyAmount ?? "")-\(secondaryCoinAmount)-\(secondaryCurrencyAmount ?? "")",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: iconUrl, placeholder: UIImage(named: iconPlaceholderImageName))
                    }
                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: primaryType.textStyle)
                        component.subtitle.set(style: secondaryType.textStyle)

                        component.title.text = primaryCoinAmount
                        component.subtitle.text = secondaryCoinAmount
                    }
                    cell.bind(index: 2) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.set(style: .d1)
                        component.subtitle.set(style: .f1)

                        component.title.textAlignment = .right
                        component.title.text = primaryCurrencyAmount

                        component.subtitle.textAlignment = .right
                        component.subtitle.text = secondaryCurrencyAmount
                    }
                }
        )
    }

    static func fromToRow(tableView: UITableView, rowInfo: RowInfo, title: String, value: String, valueTitle: String?) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .secondaryButton],
                tableView: tableView,
                id: "from-to-\(rowInfo.index)",
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    }

                    cell.bind(index: 1) { (component: SecondaryButtonComponent) in
                        component.button.set(style: .default)
                        component.button.setTitle(valueTitle ?? value, for: .normal)
                        component.button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                }
        )
    }

    static func valueRow(tableView: UITableView, rowInfo: RowInfo, iconName: String?, title: String, value: String, type: ValueType = .regular) -> RowProtocol {
        CellBuilder.row(
                elements: [.image20, .text, .text],
                tableView: tableView,
                id: "value-\(rowInfo.index)",
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        if let iconName = iconName {
                            component.isHidden = false
                            component.imageView.image = UIImage(named: iconName)?.withTintColor(.themeGray)
                        } else {
                            component.isHidden = true
                        }
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: type.textStyle)
                        component.text = value
                    }
                }
        )
    }

}

struct RowInfo {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
}

enum AmountType {
    case incoming
    case outgoing
    case neutral
    case secondary

    var showSign: Bool {
        switch self {
        case .incoming, .outgoing, .secondary: return true
        case .neutral: return false
        }
    }

    var sign: FloatingPointSign {
        switch self {
        case .incoming, .neutral, .secondary: return .plus
        case .outgoing: return .minus
        }
    }

    var textStyle: TextComponent.Style {
        switch self {
        case .incoming: return .c4
        case .outgoing: return .c5
        case .neutral: return .c2
        case .secondary: return .f1
        }
    }

}

enum ValueType {
    case regular
    case warning
    case alert

    var textStyle: TextComponent.Style {
        switch self {
        case .regular: return .c2
        case .warning: return .c3
        case .alert: return .c5
        }
    }

}
