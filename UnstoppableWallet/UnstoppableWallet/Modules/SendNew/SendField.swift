import Foundation
import Kingfisher
import MarketKit
import SwiftUI

enum SendField {
    case amount(title: String, token: Token, appValueType: AppValueType, currencyValue: CurrencyValue?, type: AmountType)
    case amountNew(token: Token, appValueType: AppValueType, currencyValue: CurrencyValue?)
    case value(title: CustomStringConvertible, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool)
    case doubleValue(title: String, description: InfoDescription?, value1: String, value2: String?)
    case levelValue(title: String, value: String, level: ValueLevel)
    case note(iconName: String?, title: String)
    case simpleValue(icon: String? = nil, title: CustomStringConvertible, value: String)
    case address(title: String? = nil, value: String, blockchainType: BlockchainType)
    case selfAddress(value: String, blockchainType: BlockchainType)
    case price(title: String, tokenA: Token, tokenB: Token, amountA: Decimal, amountB: Decimal)
    case hex(title: String, value: String)
    case mevProtection(isOn: Binding<Bool>)

    @ViewBuilder var listRow: some View {
        switch self {
        case let .amount(title, token, appValueType, currencyValue, type):
            ListRow {
                CoinIconView(coin: token.coin)

                HStack(spacing: .margin4) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).textSubhead2(color: .themeLeah)
                        Text(token.fullBadge).textCaption()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        if let formatted = appValueType.formattedFull() {
                            Text(formatted)
                                .textSubhead1(color: type.color)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("n/a".localized)
                                .textSubhead1(color: .themeGray50)
                                .multilineTextAlignment(.trailing)
                        }

                        if let formatted = currencyValue?.formattedFull {
                            Text(formatted)
                                .textCaption()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        case let .amountNew(token, appValueType, currencyValue):
            Cell(
                left: {
                    CoinIconView(token: token)
                },
                middle: {
                    MultiText(
                        title: token.coin.code,
                        subtitle: token.fullBadge,
                    )
                },
                right: {
                    RightMultiText(
                        title: appValueType.formattedFull(showCode: false),
                        subtitle: currencyValue?.formattedFull
                    )
                }
            )
        case let .value(title, appValue, currencyValue, formatFull):
            let infoDescription = (title as? SendField.InformedTitle)?.info

            Cell(
                style: .secondary,
                middle: {
                    if let infoDescription {
                        MiddleTextIcon(text: title)
                            .modifier(Informed(infoDescription: infoDescription, horizontalPadding: 0))
                    } else {
                        MiddleTextIcon(text: title)
                    }
                },
                right: {
                    let formatted = (formatFull ? appValue?.formattedFull() : appValue?.formattedShort())

                    RightMultiText(
                        subtitleSB: ComponentText(text: formatted ?? "n/a".localized, colorStyle: formatted != nil ? .primary : .secondary),
                        subtitle: formatFull ? currencyValue?.formattedFull : currencyValue?.formattedShort
                    )
                }
            )
        case let .levelValue(title, value, level):
            Cell(
                style: .secondary,
                middle: {
                    MiddleTextIcon(text: title)
                },
                right: {
                    RightTextIcon(text: ComponentText(text: value, colorStyle: level.colorStyle))
                }
            )
        case let .note(iconName, title):
            ListRow {
                if let iconName {
                    Image(iconName)
                }
                Text(title).textSubhead2()
                Spacer()
            }
        case let .address(title, value, blockchainType):
            RecipientRowsView(title: title, value: value, blockchainType: blockchainType)
        case let .selfAddress(value, blockchainType):
            Cell(
                left: {
                    ThemeImage("wallet_filled", size: .iconSize24)
                },
                middle: {
                    MultiText(subtitle: ComponentText(text: "send.confirmation.send_to_own".localized, colorStyle: .primary), description: value)
                }
            )
        case let .price(title, tokenA, tokenB, amountA, amountB):
            PriceRow(title: title, tokenA: tokenA, tokenB: tokenB, amountA: amountA, amountB: amountB)
        case let .simpleValue(icon, title, value):
            let infoDescription = (title as? SendField.InformedTitle)?.info

            Cell(
                style: .secondary,
                left: {
                    if let icon {
                        ThemeImage(icon, size: .iconSize20)
                    }
                },
                middle: {
                    if let infoDescription {
                        MiddleTextIcon(text: title)
                            .modifier(Informed(infoDescription: infoDescription, horizontalPadding: 0))

                    } else {
                        MiddleTextIcon(text: title)
                    }
                },
                right: {
                    RightMultiText(subtitle: ComponentText(text: value, colorStyle: .primary))
                }
            )
        case let .hex(title, value):
            ListRow {
                Text(title).textSubhead2()

                Spacer()

                Text(value)
                    .textSubhead1(color: .themeLeah)
                    .lineLimit(3)
                    .truncationMode(.middle)

                Button(action: {
                    CopyHelper.copyAndNotify(value: value)
                }) {
                    Image("copy_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            }
        case let .mevProtection(isOn):
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image("star_filled_16").themeIcon(color: .themeJacob)
                    Text("subscription.premium.label".localized).themeSubhead1(color: .themeJacob)
                }
                .padding(.horizontal, .margin16)
                .frame(height: .margin32)

                ListSection {
                    ListRow {
                        Image("shield_24").themeIcon(color: .themeJacob)
                        Toggle(isOn: isOn) {
                            Text("mev_protection.title".localized).themeBody()
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                    }
                }
                .modifier(ThemeListStyleModifier(themeListStyle: .borderedLawrence, selected: true))

                ListSectionFooter(text: "mev_protection.description".localized)
            }
        case let .doubleValue(title, infoDescription, value1, value2):
            ListRow(padding: EdgeInsets(top: .margin12, leading: infoDescription == nil ? .margin16 : 0, bottom: .margin12, trailing: .margin16)) {
                if let infoDescription {
                    Text(title)
                        .textSubhead2()
                        .modifier(Informed(infoDescription: infoDescription))
                } else {
                    Text(title)
                        .textSubhead2()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(value1)
                        .textSubhead1(color: .themeLeah)
                        .multilineTextAlignment(.trailing)

                    if let value2 {
                        Text(value2)
                            .textSubhead1(color: .themeLeah)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    enum AppValueType {
        case regular(appValue: AppValue)
        case infinity(code: String)
        case withoutAmount(code: String)

        private func formatted(full: Bool, showCode: Bool = true) -> String? {
            switch self {
            case let .regular(appValue): return full ? appValue.formattedFull(showCode: showCode) : appValue.formattedShort()
            case let .infinity(code): return showCode ? "∞ \(code)" : "∞"
            case let .withoutAmount(code): return "\(code)"
            }
        }

        func formattedFull(showCode: Bool = true) -> String? {
            formatted(full: true, showCode: showCode)
        }

        var formattedShort: String? {
            formatted(full: false)
        }
    }

    enum AmountType {
        case incoming
        case outgoing
        case neutral

        var sign: FloatingPointSign {
            switch self {
            case .incoming, .neutral: return .plus
            case .outgoing: return .minus
            }
        }

        var color: Color {
            switch self {
            case .incoming: return .themeRemus
            case .neutral, .outgoing: return .themeLeah
            }
        }
    }
}

extension SendField {
    struct InformedTitle: CustomStringConvertible {
        let title: String
        let info: InfoDescription

        var description: String { title }

        init(_ title: String, info: InfoDescription) {
            self.title = title
            self.info = info
        }
    }
}

extension SendField {
    static func recipient(_ recipient: String, blockchainType: BlockchainType) -> Self {
        .address(
            title: "swap.recipient".localized,
            value: recipient,
            blockchainType: blockchainType
        )
    }

    static func slippage(_ slippage: Decimal) -> Self? {
        guard slippage != MultiSwapSlippage.default else {
            return nil
        }

        return .levelValue(
            title: "swap.slippage".localized,
            value: "\(slippage.description)%",
            level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
        )
    }

    static func minRecieve(token: Token, value: Decimal) -> Self? {
        guard let formatted = AppValue(token: token, value: value).formattedShort() else {
            return nil
        }

        return .levelValue(
            title: "swap.confirmation.minimum_received".localized,
            value: formatted,
            level: .regular
        )
    }
}
