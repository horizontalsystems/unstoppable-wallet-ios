import Foundation
import Kingfisher
import MarketKit
import SwiftUI

/// The open rendering seam for send/swap confirmation fields.
///
/// Each field variant conforms to `SendFieldContent` and renders itself via
/// `listRow()`, returning its own opaque `Row` view. Type erasure to `AnyView`
/// is deferred: `SendField.init` captures the concrete content in a `@MainActor`
/// closure and only erases when that closure is invoked at the render site, so
/// variant bodies stay free of `AnyView` wrapping and `init` stays nonisolated.
///
/// External modules that depend on WalletCore can add brand-new field variants
/// without editing any WalletCore source. For example:
///
/// ```swift
/// public struct FooField: SendFieldContent {
///     public let text: String
///     public init(text: String) { self.text = text }
///
///     public func listRow() -> some View {
///         Text(text)
///     }
/// }
///
/// // Then wrap it and place it in a section:
/// let section = SendDataSection([SendField(FooField(text: "Hello"))])
/// ```
public protocol SendFieldContent {
    associatedtype Row: View
    @ViewBuilder @MainActor func listRow() -> Row
}

public struct SendField {
    public let content: any SendFieldContent
    private let _row: @MainActor () -> AnyView

    public init(_ content: some SendFieldContent) {
        self.content = content
        // Lazy erasure: capture the concrete (value-type) content in a
        // `@MainActor` closure and erase to `AnyView` only when the closure is
        // invoked at the render site. Forming the closure does not call
        // `listRow()`, so `init` stays nonisolated and can run on any actor —
        // `SendField` is built off the main actor on real send/swap paths.
        _row = { @MainActor in AnyView(content.listRow()) }
    }

    @MainActor public func listRow() -> AnyView { _row() }
}

public struct AmountField: SendFieldContent {
    public let token: Token
    public let appValueType: SendField.AppValueType
    public let currencyValue: CurrencyValue?

    public init(token: Token, appValueType: SendField.AppValueType, currencyValue: CurrencyValue?) {
        self.token = token
        self.appValueType = appValueType
        self.currencyValue = currencyValue
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        Cell(
            left: {
                CoinIconView(token: token)
            },
            middle: {
                MultiText(
                    eyebrow: ComponentText(text: token.coin.code, colorStyle: .primary),
                    subtitle: token.fullBadge
                )
            },
            right: {
                RightMultiText(
                    eyebrow: appValueType.formattedFull(showCode: false).map { ComponentText(text: $0, colorStyle: .primary) },
                    subtitle: currencyValue?.formattedFull
                )
            }
        )
    }
}

public struct ValueField: SendFieldContent {
    public let title: CustomStringConvertible
    public let appValue: AppValue?
    public let currencyValue: CurrencyValue?
    public let formatFull: Bool

    public init(title: CustomStringConvertible, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool) {
        self.title = title
        self.appValue = appValue
        self.currencyValue = currencyValue
        self.formatFull = formatFull
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title).styled(title)
            },
            right: {
                let formatted = (formatFull ? appValue?.formattedFull() : appValue?.formattedShort())

                RightMultiText(
                    eyebrow: ComponentText(text: formatted ?? "n/a".localized, colorStyle: formatted != nil ? .primary : .secondary),
                    subtitle: formatFull ? currencyValue?.formattedFull : currencyValue?.formattedShort
                )
            }
        )
    }
}

public struct DoubleValueField: SendFieldContent {
    public let title: String
    public let description: InfoDescription?
    public let value1: String
    public let value2: String?

    public init(title: String, description: InfoDescription?, value1: String, value2: String?) {
        self.title = title
        self.description = description
        self.value1 = value1
        self.value2 = value2
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        let infoDescription = description
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

public struct LevelValueField: SendFieldContent {
    public let title: String
    public let value: String
    public let level: ValueLevel

    public init(title: String, value: String, level: ValueLevel) {
        self.title = title
        self.value = value
        self.level = level
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title)
            },
            right: {
                RightMultiText(subtitle: ComponentText(text: value, colorStyle: level.colorStyle))
            }
        )
    }
}

public struct NoteField: SendFieldContent {
    public let iconName: String?
    public let title: String

    public init(iconName: String?, title: String) {
        self.iconName = iconName
        self.title = title
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        ListRow {
            if let iconName {
                Image(iconName)
            }
            Text(title).textSubhead2()
            Spacer()
        }
    }
}

public struct SimpleValueField: SendFieldContent {
    public let icon: String?
    public let title: CustomStringConvertible
    public let value: CustomStringConvertible

    public init(icon: String? = nil, title: CustomStringConvertible, value: CustomStringConvertible) {
        self.icon = icon
        self.title = title
        self.value = value
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        Cell(
            style: .secondary,
            left: {
                if let icon {
                    ThemeImage(icon, size: .iconSize20)
                }
            },
            middle: {
                MiddleTextIcon(text: title).styled(title)
            },
            right: {
                RightMultiText(subtitle: value.styled(.primary))
            }
        )
    }
}

public struct AddressField: SendFieldContent {
    public let value: String
    public let blockchainType: BlockchainType

    public init(value: String, blockchainType: BlockchainType) {
        self.value = value
        self.blockchainType = blockchainType
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        AddressRowsView(value: value, blockchainType: blockchainType)
    }
}

public struct RecipientField: SendFieldContent {
    public let title: String
    public let value: String
    public let copyable: Bool
    public let blockchainType: BlockchainType

    public init(title: String, value: String, copyable: Bool, blockchainType: BlockchainType) {
        self.title = title
        self.value = value
        self.copyable = copyable
        self.blockchainType = blockchainType
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        RecipientRowsView(title: title, value: value, copyable: copyable, blockchainType: blockchainType)
    }
}

public struct SelfAddressField: SendFieldContent {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        Cell(
            left: {
                ThemeImage("wallet_filled", size: .iconSize24)
            },
            middle: {
                MultiText(subtitle: ComponentText(text: "send.confirmation.send_to_own".localized, colorStyle: .primary), description: value)
            }
        )
    }
}

public struct PriceField: SendFieldContent {
    public let title: String
    public let tokenA: Token
    public let tokenB: Token
    public let amountA: Decimal
    public let amountB: Decimal

    public init(title: String, tokenA: Token, tokenB: Token, amountA: Decimal, amountB: Decimal) {
        self.title = title
        self.tokenA = tokenA
        self.tokenB = tokenB
        self.amountA = amountA
        self.amountB = amountB
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        let priceData = FlipRow.TokenPriceData(tokenA: tokenA, tokenB: tokenB, amountA: amountA, amountB: amountB)
        FlipRow(title: title, flipData: priceData)
    }
}

public struct FeeField: SendFieldContent {
    public let title: CustomStringConvertible
    public let amountData: AmountData?

    public init(title: CustomStringConvertible, amountData: AmountData?) {
        self.title = title
        self.amountData = amountData
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        let feeData = FlipRow.TokenFeeData(amountData: amountData)
        FlipRow(title: title, flipData: feeData, initialFlipped: false)
    }
}

public struct HexField: SendFieldContent {
    public let title: String
    public let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
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
    }
}

public struct MevProtectionField: SendFieldContent {
    public let isOn: Binding<Bool>

    public init(isOn: Binding<Bool>) {
        self.isOn = isOn
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        VStack(spacing: 0) {
            SectionHeader(image: Image.defenseIcon, text: "purchases.swap_protection".localized, horizontalInsets: .margin16)
            ListSection {
                Cell(
                    middle: {
                        MiddleTextIcon(text: "mev_protection.title".localized)
                    },
                    right: {
                        ThemeToggle(isOn: isOn)
                    }
                )
            }
            .themeListStyle(.bordered)

            ListSectionFooter(text: "mev_protection.description".localized)
        }
    }
}

public struct TimerField: SendFieldContent {
    public let title: CustomStringConvertible
    public let expirationDate: Date

    public init(title: CustomStringConvertible, expirationDate: Date) {
        self.title = title
        self.expirationDate = expirationDate
    }

    @ViewBuilder @MainActor public func listRow() -> some View {
        ExpirationTimerCell(title: title, expirationDate: expirationDate)
    }
}

extension SendField {
    public enum AppValueType {
        case regular(appValue: AppValue)
        case infinity(code: String)
        case withoutAmount(code: String)

        private func formatted(full: Bool, showCode: Bool = true) -> String? {
            switch self {
            case let .regular(appValue): return full ? appValue.formattedFull(showCode: showCode) : appValue.formattedShort()
            case let .infinity(code): return "swap.unlock.unlimited".localized + (showCode ? "\(code)" : "")
            case let .withoutAmount(code): return "\(code)"
            }
        }

        public func formattedFull(showCode: Bool = true) -> String? {
            formatted(full: true, showCode: showCode)
        }

        public var formattedShort: String? {
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

public extension SendField {
    static func amount(token: Token, appValueType: AppValueType, currencyValue: CurrencyValue?) -> SendField {
        SendField(AmountField(token: token, appValueType: appValueType, currencyValue: currencyValue))
    }

    static func value(title: CustomStringConvertible, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool) -> SendField {
        SendField(ValueField(title: title, appValue: appValue, currencyValue: currencyValue, formatFull: formatFull))
    }

    static func doubleValue(title: String, description: InfoDescription?, value1: String, value2: String?) -> SendField {
        SendField(DoubleValueField(title: title, description: description, value1: value1, value2: value2))
    }

    static func levelValue(title: String, value: String, level: ValueLevel) -> SendField {
        SendField(LevelValueField(title: title, value: value, level: level))
    }

    static func note(iconName: String?, title: String) -> SendField {
        SendField(NoteField(iconName: iconName, title: title))
    }

    static func simpleValue(icon: String? = nil, title: CustomStringConvertible, value: CustomStringConvertible) -> SendField {
        SendField(SimpleValueField(icon: icon, title: title, value: value))
    }

    static func address(value: String, blockchainType: BlockchainType) -> SendField {
        SendField(AddressField(value: value, blockchainType: blockchainType))
    }

    static func recipient(title: String, value: String, copyable: Bool, blockchainType: BlockchainType) -> SendField {
        SendField(RecipientField(title: title, value: value, copyable: copyable, blockchainType: blockchainType))
    }

    static func selfAddress(value: String) -> SendField {
        SendField(SelfAddressField(value: value))
    }

    static func price(title: String, tokenA: Token, tokenB: Token, amountA: Decimal, amountB: Decimal) -> SendField {
        SendField(PriceField(title: title, tokenA: tokenA, tokenB: tokenB, amountA: amountA, amountB: amountB))
    }

    static func fee(title: CustomStringConvertible, amountData: AmountData?) -> SendField {
        SendField(FeeField(title: title, amountData: amountData))
    }

    static func hex(title: String, value: String) -> SendField {
        SendField(HexField(title: title, value: value))
    }

    static func mevProtection(isOn: Binding<Bool>) -> SendField {
        SendField(MevProtectionField(isOn: isOn))
    }

    static func timer(title: CustomStringConvertible, expirationDate: Date) -> SendField {
        SendField(TimerField(title: title, expirationDate: expirationDate))
    }
}

public extension SendField {
    static func recipient(_ recipient: String, copyable: Bool = false, blockchainType: BlockchainType) -> SendField {
        .recipient(
            title: "swap.recipient".localized,
            value: recipient,
            copyable: copyable,
            blockchainType: blockchainType
        )
    }

    static func slippage(_ slippage: Decimal) -> SendField? {
        guard slippage != MultiSwapSlippage.default else {
            return nil
        }

        return .simpleValue(
            title: "swap.slippage".localized,
            value: ComponentText(text: "\(slippage.description)%", colorStyle: MultiSwapSlippage.validate(slippage: slippage).valueLevel.colorStyle)
        )
    }

    static func minRecieve(token: Token, value: Decimal) -> SendField? {
        guard let formatted = AppValue(token: token, value: value).formattedShort() else {
            return nil
        }

        return .simpleValue(
            title: ComponentInformedTitle("swap.confirmation.minimum_received".localized, info: InfoDescription(
                title: "swap.confirmation.minimum_received".localized,
                description: "swap.confirmation.minimum_received.info".localized
            )),
            value: formatted
        )
    }
}
