import EvmKit
import Foundation
import MarketKit

struct EvmDecoration {
    let type: Type
    let customSendButtonTitle: String?

    var rateCoins: [Coin] {
        switch type {
        case let .outgoingEip20(_, _, token): return [token.coin]
        case let .approveEip20(_, _, token): return [token.coin]
        default: return []
        }
    }

    func flowSection(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection? {
        switch type {
        case let .outgoingEvm(to, value):
            return outgoingFlow(token: baseToken, to: to, value: value, currency: currency, rates: rates)
        case let .outgoingEip20(to, value, token):
            return outgoingFlow(token: token, to: to, value: value, currency: currency, rates: rates)
        case let .approveEip20(spender, value, token):
            return approveFlowSection(token: token, spender: spender, value: value, currency: currency, rates: rates)
        case let .unknown(to, value, _, _):
            return outgoingFlow(token: baseToken, to: to, value: value, currency: currency, rates: rates)
        }
    }

    func fields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        switch type {
        case .outgoingEvm, .outgoingEip20, .approveEip20:
            return []
        case let .unknown(to, value, input, method):
            return unknownFields(baseToken: baseToken, to: to, value: value, input: input, method: method, currency: currency, rates: rates)
        }
    }

    private func outgoingFlow(token: Token, to: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
        let appValue = AppValue(token: token, value: value)
        let rate = rates[token.coin.uid]
        let currencyValue = rate.map { CurrencyValue(currency: currency, value: $0 * value) }

        return .init([
            .amountNew(
                token: token,
                appValueType: .regular(appValue: appValue),
                currencyValue: currencyValue,
            ),
            .address(
                value: to.eip55,
                blockchainType: token.blockchainType
            ),
        ], isFlow: true)
    }

    private func unknownFlow(token: Token, to: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
        let appValue = AppValue(token: token, value: value)
        let rate = rates[token.coin.uid]
        let currencyValue = rate.map { CurrencyValue(currency: currency, value: $0 * value) }

        return .init([
            .amountNew(
                token: token,
                appValueType: .regular(appValue: appValue),
                currencyValue: currencyValue,
            ),
            .address(
                value: to.eip55,
                blockchainType: token.blockchainType
            ),
        ], isFlow: true)
    }

    private func approveFlowSection(token: Token, spender: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
        let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance

        let amountField: SendField

        if isRevokeAllowance {
            amountField = .amountNew(
                token: token,
                appValueType: .withoutAmount(code: token.coin.code),
                currencyValue: nil,
            )
        } else {
            amountField = self.amountField(
                token: token,
                value: value,
                currency: currency,
                rate: rates[token.coin.uid],
            )
        }

        return .init([
            amountField,
            .address(
                value: spender.eip55,
                blockchainType: token.blockchainType
            )
        ])                     
    }

    private func unknownFields(baseToken _: Token, to _: EvmKit.Address, value: Decimal, input: Data, method: String?, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
        var fields: [SendField] = [
            .simpleValue(title: "send.confirmation.input".localized, value: input.toHexString()),
        ]

        if let method {
            fields.append(.simpleValue(title: "send.confirmation.method".localized, value: method))
        }

        return fields
    }

    private func amountField(token: Token, value: Decimal, currency: Currency, rate: Decimal?) -> SendField {
        let appValue = AppValue(token: token, value: Decimal(sign: .plus, exponent: value.exponent, significand: value.significand))

        return .amountNew(
            token: token,
            appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
            currencyValue: appValue.isMaxValue ? nil : rate.map { CurrencyValue(currency: currency, value: $0 * value) },
        )
    }
}

extension EvmDecoration {
    enum `Type` {
        case outgoingEvm(to: EvmKit.Address, value: Decimal)
        case outgoingEip20(to: EvmKit.Address, value: Decimal, token: Token)
        case approveEip20(spender: EvmKit.Address, value: Decimal, token: Token)
        case unknown(to: EvmKit.Address, value: Decimal, input: Data, method: String?)
    }
}
