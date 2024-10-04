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

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        switch type {
        case let .outgoingEvm(to, value):
            return outgoingSections(token: baseToken, to: to, value: value, currency: currency, rates: rates)
        case let .outgoingEip20(to, value, token):
            return outgoingSections(token: token, to: to, value: value, currency: currency, rates: rates)
        case let .approveEip20(spender, value, token):
            return approveSections(token: token, spender: spender, value: value, currency: currency, rates: rates)
        case let .unknown(to, value, input, method):
            return unknownSections(baseToken: baseToken, to: to, value: value, input: input, method: method, currency: currency, rates: rates)
        }
    }

    private func outgoingSections(token: Token, to: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        [
            [
                amountField(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    value: value,
                    currency: currency,
                    rate: rates[token.coin.uid],
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: to.eip55,
                    blockchainType: token.blockchainType
                ),
            ],
        ]
    }

    private func approveSections(token: Token, spender: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance

        let amountField: SendField

        if isRevokeAllowance {
            amountField = .amount(
                title: "approve.confirmation.you_revoke".localized,
                token: token,
                appValueType: .withoutAmount(code: token.coin.code),
                currencyValue: nil,
                type: .neutral
            )
        } else {
            amountField = self.amountField(
                title: "approve.confirmation.you_approve".localized,
                token: token,
                value: value,
                currency: currency,
                rate: rates[token.coin.uid],
                type: .neutral
            )
        }

        return [
            [
                amountField,
                .address(
                    title: "approve.confirmation.spender".localized,
                    value: spender.eip55,
                    blockchainType: token.blockchainType
                ),
            ],
        ]
    }

    private func unknownSections(baseToken: Token, to: EvmKit.Address, value: Decimal, input: Data, method: String?, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        var fields: [SendField] = [
            amountField(
                title: "send.confirmation.transfer".localized,
                token: baseToken,
                value: value,
                currency: currency,
                rate: rates[baseToken.coin.uid],
                type: .neutral
            ),
            .address(
                title: "send.confirmation.to".localized,
                value: to.eip55,
                blockchainType: baseToken.blockchainType
            ),
            .hex(title: "send.confirmation.input".localized, value: input.toHexString()),
        ]

        if let method {
            fields.append(.levelValue(title: "send.confirmation.method".localized, value: method, level: .regular))
        }

        return [fields]
    }

    private func amountField(title: String, token: Token, value: Decimal, currency: Currency, rate: Decimal?, type: SendField.AmountType) -> SendField {
        let appValue = AppValue(token: token, value: Decimal(sign: type.sign, exponent: value.exponent, significand: value.significand))

        return .amount(
            title: title,
            token: token,
            appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
            currencyValue: appValue.isMaxValue ? nil : rate.map { CurrencyValue(currency: currency, value: $0 * value) },
            type: type
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
