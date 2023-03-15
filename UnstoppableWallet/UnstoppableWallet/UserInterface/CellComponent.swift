import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import MarketKit

struct CellComponent {

    static func actionTitleRow(tableView: SectionsTableView, rowInfo: RowInfo, iconName: String?, iconDimmed: Bool, title: String, value: String) -> RowProtocol {
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

    static func amountRow(tableView: SectionsTableView, rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType, action: (() -> ())? = nil) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image32 { (component: ImageComponent) -> () in
                        component.setImage(urlString: iconUrl, placeholder: UIImage(named: iconPlaceholderImageName))
                    },
                    .text { (component: TextComponent) -> () in
                        component.font = type.textFont
                        component.textColor = type.textColor
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = coinAmount
                    },
                    .text { (component: TextComponent) -> () in
                        component.isHidden = currencyAmount == nil
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = currencyAmount
                    }
                ]),
                tableView: tableView,
                id: "amount-\(rowInfo.index)",
                hash: "amount-\(coinAmount)-\(currencyAmount ?? "")",
                height: .heightCell56,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                },
                action: action
        )
    }

    static func nftAmountRow(tableView: SectionsTableView, rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, nftAmount: String, type: AmountType, onTapOpenNft: (() -> ())?) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image32 { component in
                        component.imageView.kf.setImage(with: iconUrl.flatMap { URL(string: $0) }, placeholder: UIImage(named: iconPlaceholderImageName), options: [.onlyLoadFirstFrame, .transition(.fade(0.5))])
                        component.imageView.cornerRadius = .cornerRadius4
                        component.imageView.contentMode = .scaleAspectFill
                    },
                    .text { component in
                        component.font = type.textFont
                        component.textColor = type.textColor
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = nftAmount
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

    static func doubleAmountRow(tableView: SectionsTableView, rowInfo: RowInfo, title: String, coinValue: String, currencyValue: String?) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { (component: TextComponent) -> () in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    },
                    .vStackCentered([
                        .text { (component: TextComponent) -> () in
                            component.font = .subhead2
                            component.textColor = .themeLeah
                            component.textAlignment = .right
                            component.text = coinValue
                        },
                        .margin(1),
                        .text { (component: TextComponent) -> () in
                            component.font = .caption
                            component.textColor = .themeGray
                            component.textAlignment = .right
                            component.text = currencyValue
                        }
                    ])
                ]),
                tableView: tableView,
                id: "double-amount-\(rowInfo.index)",
                hash: "double-amount-\(coinValue)-\(currencyValue ?? "-")",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                }
        )
    }

    static func fromToRow(tableView: UITableView, rowInfo: RowInfo, title: String, value: String, valueTitle: String?, onAddToContact: (() -> ())? = nil) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let titleFont: UIFont = .subhead2
        let valueFont: UIFont = .subhead1
        let inContact = onAddToContact != nil

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = titleFont
                        component.textColor = .themeGray
                        component.text = title
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    },
                    .text { component in
                        component.font = valueFont
                        component.textColor = .themeLeah
                        component.text = value
                        component.textAlignment = .right
                        component.numberOfLines = 0
                    },
                    .secondaryCircleButton { component in
                        component.button.set(image: UIImage(named: "user_plus_20"))
                        component.isHidden = onAddToContact == nil
                        component.onTap = {
                            onAddToContact?()
                        }
                    },
                    .secondaryCircleButton { component in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                ]),
                tableView: tableView,
                id: "from-to-\(rowInfo.index)",
                hash: value + inContact.description + rowInfo.description,
                dynamicHeight: { containerWidth in
                    CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: value,
                            font: valueFont,
                            elements: [
                                .fixed(width: TextComponent.width(font: titleFont, text: title)),
                                .multiline,
                                .margin8,
                                .fixed(width: SecondaryCircleButton.size)
                            ]
                    )
                },
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                }
        )
    }

    static func valueRow(tableView: UITableView, rowInfo: RowInfo, iconName: String?, title: String, value: String, type: ValueType = .regular) -> RowProtocol {
        CellBuilder.row(
                elements: [.image20, .text, .text],
                tableView: tableView,
                id: "from-to-\(rowInfo.index)",
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                }
        )
    }

    static func valueRow(tableView: SectionsTableView, rowInfo: RowInfo, iconName: String?, title: String, value: String, type: ValueType = .regular) -> RowProtocol {
        tableView.universalRow48(
                id: "value-\(rowInfo.index)",
                image: iconName.flatMap { UIImage(named: $0)?.withTintColor(.themeGray) }.map { .local($0) },
                title: .subhead2(title),
                value: .subhead1(value, color: type.textColor),
                hash: value,
                isFirst: rowInfo.isFirst,
                isLast: rowInfo.isLast
        )
    }

    static func blockchainAddress(tableView: UITableView, rowInfo: RowInfo, imageUrl: String, title: String, value: String, editType: EditType, action: (()->())? = nil) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let titleFont: UIFont = .subhead1
        let valueFont: UIFont = .subhead2
        let titleValueMargin: CGFloat = 1
        let showEdit = editType != .none
        let editColor: UIColor = editType == .original ? .themeGray : .themeJacob

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .imageElement(image: .url(imageUrl, placeholder: "placeholder_rectangle_32"), size: .image32),
                    .vStackCentered([
                        .textElement(text: .subhead1(title), parameters: .allCompression),
                        .margin(titleValueMargin),
                        .textElement(text: .subhead2(value), parameters: .multiline)
                    ]),
                    .imageElement(image: showEdit ? .local(UIImage(named: "edit_20")?.withTintColor(editColor)) : nil, size: .image20)
                ]),
                tableView: tableView,
                id: "from-to-\(rowInfo.index)",
                hash: title + value,
                autoDeselect: action != nil,
                dynamicHeight: { containerWidth in
                    var elements: [CellBuilderNew.LayoutElement] = [
                        .fixed(width: .iconSize32),
                        .multiline
                    ]

                    if showEdit {
                        elements.append(.fixed(width: .iconSize20))
                    }

                    let height = CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: value,
                            font: valueFont,
                            verticalPadding: .margin12,
                            elements: elements
                    )

                    return height + titleFont.lineHeight + titleValueMargin
                },
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                },
                action: action
        )
    }

}

struct RowInfo {
    let index: Int
    let isFirst: Bool
    let isLast: Bool

    init(index: Int, isFirst: Bool, isLast: Bool) {
        self.index = index
        self.isFirst = isFirst
        self.isLast = isLast
    }

    init(index: Int, count: Int) {
        self.index = index
        isFirst = index == 0
        isLast = index == count - 1
    }

    var description: String {
        index.description + isFirst.description + isLast.description
    }

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

enum EditType {
    case none
    case original
    case edited
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
