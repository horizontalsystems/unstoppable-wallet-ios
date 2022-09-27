import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit

struct CellComponent {

    static func actionTitleRow(tableView: UITableView, rowInfo: RowInfo, iconName: String?, iconDimmed: Bool, title: String, value: String) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        if let iconName = iconName {
                            component.isHidden = false
                            component.imageView.image = UIImage(named: iconName)?.withTintColor(iconDimmed ? .themeGray : .themeLeah)
                        } else {
                            component.isHidden = true
                        }
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    },
                    .text { component in
                        component.font = .subhead1
                        component.textColor = .themeGray
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = value
                    }
                ]),
                tableView: tableView,
                id: "action-\(rowInfo.index)",
                hash: "action-\(value)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
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
                        component.font = type.textFont
                        component.textColor = type.textColor
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = coinAmount
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.isHidden = currencyAmount == nil
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = currencyAmount
                    }
                }
        )
    }

    static func nftAmountRow(tableView: UITableView, rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, nftAmount: String, type: AmountType, onTapOpenNft: (() -> ())?) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.setImage(urlString: iconUrl, placeholder: UIImage(named: iconPlaceholderImageName))
                        component.imageView.cornerRadius = .cornerRadius4
                        component.imageView.contentMode = .scaleAspectFill
                    },
                    .text { component in
                        component.font = type.textFont
                        component.textColor = type.textColor
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = nftAmount
                    },
                    .image20 { component in
                        component.isHidden = onTapOpenNft == nil
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    }
                ]),
                tableView: tableView,
                id: "nft-amount-\(rowInfo.index)",
                hash: "\(nftAmount)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                },
                action: onTapOpenNft
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
                        component.title.font = primaryType.textFont
                        component.title.textColor = primaryType.textColor
                        component.subtitle.font = secondaryType.textFont
                        component.subtitle.textColor = secondaryType.textColor

                        component.title.text = primaryCoinAmount
                        component.subtitle.text = secondaryCoinAmount
                    }
                    cell.bind(index: 2) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.font = .subhead2
                        component.title.textColor = .themeGray
                        component.subtitle.font = .caption
                        component.subtitle.textColor = .themeGray

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
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    }

                    cell.bind(index: 1) { (component: SecondaryButtonComponent) in
                        component.button.set(style: .default)
                        component.button.setTitle(valueTitle ?? value.shortened, for: .normal)
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
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = type.textColor
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

    var textFont: UIFont {
        switch self {
        case .incoming, .outgoing, .neutral: return .subhead1
        case .secondary: return .caption
        }
    }

    var textColor: UIColor {
        switch self {
        case .incoming: return .themeRemus
        case .outgoing: return .themeLucian
        case .neutral: return .themeLeah
        case .secondary: return .themeGray
        }
    }

}

enum ValueType {
    case regular
    case warning
    case alert

    var textColor: UIColor {
        switch self {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .alert: return .themeLucian
        }
    }

}
