import Foundation
import Kingfisher
import MarketKit
import SwiftUI

enum SendField {
    case amount(title: String, token: Token, appValueType: AppValueType, currencyValue: CurrencyValue?, type: AmountType)
    case value(title: String, description: InfoDescription?, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool)
    case doubleValue(title: String, description: InfoDescription?, value1: String, value2: String?)
    case levelValue(title: String, value: String, level: ValueLevel)
    case note(iconName: String?, title: String)
    case address(title: String, value: String, blockchainType: BlockchainType)
    case price(title: String, tokenA: Token, tokenB: Token, amountA: Decimal, amountB: Decimal)
    case hex(title: String, value: String)

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
                        if let formatted = appValueType.formattedFull {
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
        case let .value(title, infoDescription, appValue, currencyValue, formatFull):
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
                    if let formatted = (formatFull ? appValue?.formattedFull() : appValue?.formattedShort()) {
                        Text(formatted)
                            .textSubhead1(color: .themeLeah)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("n/a".localized)
                            .textSubhead1()
                            .multilineTextAlignment(.trailing)
                    }

                    if let formatted = (formatFull ? currencyValue?.formattedFull : currencyValue?.formattedShort) {
                        Text(formatted)
                            .textCaption()
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        case let .levelValue(title, value, level):
            ListRow {
                Text(title).textSubhead2()
                Spacer()
                Text(value)
                    .textSubhead1(color: color(valueLevel: level))
                    .multilineTextAlignment(.trailing)
            }
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
        case let .price(title, tokenA, tokenB, amountA, amountB):
            PriceRow(title: title, tokenA: tokenA, tokenB: tokenB, amountA: amountA, amountB: amountB)
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

    private func color(valueLevel: ValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .error: return .themeLucian
        }
    }

    enum AppValueType {
        case regular(appValue: AppValue)
        case infinity(code: String)
        case withoutAmount(code: String)

        private func formatted(full: Bool) -> String? {
            switch self {
            case let .regular(appValue): return full ? appValue.formattedFull() : appValue.formattedShort()
            case let .infinity(code): return "∞ \(code)"
            case let .withoutAmount(code): return "\(code)"
            }
        }

        var formattedFull: String? {
            formatted(full: true)
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
