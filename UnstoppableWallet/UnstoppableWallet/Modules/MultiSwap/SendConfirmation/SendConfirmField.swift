import Foundation
import Kingfisher
import MarketKit
import SwiftUI

enum SendConfirmField {
    case amount(title: String, token: Token, coinValueType: CoinValueType, currencyValue: CurrencyValue?, type: AmountType)
    case value(title: String, description: AlertView.InfoDescription?, coinValue: CoinValue?, currencyValue: CurrencyValue?)
    case levelValue(title: String, value: String, level: ValueLevel)
    case address(title: String, value: String)

    @ViewBuilder var listRow: some View {
        switch self {
        case let .amount(title, token, coinValueType, currencyValue, type):
            ListRow {
                KFImage.url(URL(string: token.coin.imageUrl))
                    .resizable()
                    .placeholder {
                        Circle().fill(Color.themeSteel20)
                    }
                    .clipShape(Circle())
                    .frame(width: .iconSize24, height: .iconSize24)

                VStack(spacing: 1) {
                    HStack(spacing: .margin4) {
                        Text(title).textSubhead2(color: .themeLeah)
                        Spacer()
                        Text(coinValueType.formatted(full: true) ?? "n/a".localized).textSubhead1(color: .themeLeah)
                    }

                    HStack(spacing: .margin4) {
                        if let protocolName = token.protocolName {
                            Text(protocolName).textCaption()
                        }

                        Spacer()

                        if let formatted = currencyValue?.formattedFull {
                            Text(formatted).textCaption()
                        }
                    }
                }
            }
        case let .value(title, description, coinValue, currencyValue):
            ListRow(padding: EdgeInsets(top: .margin12, leading: description == nil ? .margin16 : 0, bottom: .margin12, trailing: .margin16)) {
                if let description {
                    Text(title)
                        .textSubhead2()
                        .modifier(Informed(description: description))
                } else {
                    Text(title)
                        .textSubhead2()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    if let formatted = coinValue?.formattedShort {
                        Text(formatted)
                            .textSubhead1(color: .themeLeah)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("n/a".localized)
                            .textSubhead1()
                            .multilineTextAlignment(.trailing)
                    }

                    if let formatted = currencyValue?.formattedShort {
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
                Text(value).textSubhead1(color: color(valueLevel: level))
            }
        case let .address(title, value):
            ListRow {
                Text(title).textSubhead2()

                Spacer()

                Text(value)
                    .textSubhead1(color: .themeLeah)
                    .multilineTextAlignment(.trailing)

                Button(action: {
                    CopyHelper.copyAndNotify(value: value)
                }) {
                    Image("copy_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
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

    enum CoinValueType {
        case regular(coinValue: CoinValue)
        case infinity(kind: CoinValue.Kind)
        case withoutAmount(kind: CoinValue.Kind)

        func formatted(full: Bool = false) -> String? {
            switch self {
            case let .regular(coinValue): return full ? ValueFormatter.instance.formatFull(coinValue: coinValue) : ValueFormatter.instance.formatShort(coinValue: coinValue)
            case let .infinity(kind): return "∞ \(kind.symbol)"
            case let .withoutAmount(kind): return "\(kind.symbol)"
            }
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
    }
}
