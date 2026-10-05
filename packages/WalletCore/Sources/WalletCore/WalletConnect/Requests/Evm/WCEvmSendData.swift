import EvmKit
import Foundation
import MarketKit

// The EVM rows of the request card without the fee, which the wrapper places after network and wallet
class WCEvmSendData: ISendData {
    let evmSendData: EvmSendData

    init(evmSendData: EvmSendData) {
        self.evmSendData = evmSendData
    }

    var feeData: FeeData? { evmSendData.feeData }
    var canSend: Bool { evmSendData.canSend }
    var rateCoins: [Coin] { evmSendData.rateCoins }
    var amountAdjusted: Bool { evmSendData.amountAdjusted }

    var customSendButtonTitle: String? {
        if case .approveEip20 = evmSendData.decoration.type {
            return "swap.approve".localized
        }
        return nil
    }

    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        // Android WCSendEthScreen FeeCell shows coin amount and fiat together (no flip); while the gas
        // estimate is still pending (no fee and no error yet) the row shows a spinner instead of blocking
        // the whole sheet. A failed estimate (transactionError set) falls back to n/a plus the red caution.
        let amountData = evmSendData.evmFeeData?.totalAmountData(gasPrice: evmSendData.gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
        let loading = evmSendData.evmFeeData == nil && evmSendData.transactionError == nil
        return [SendField(WCFeeField(title: ComponentInformedTitle("send.confirmation.fee".localized, info: .fee), amountData: amountData, loading: loading))]
    }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        evmSendData.cautions(baseToken: baseToken, currency: currency, rates: rates)
    }

    func sections(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        let decoration = evmSendData.decoration
        var fields: [SendField]

        switch decoration.type {
        case let .approveEip20(spender, value, token):
            let appValue = AppValue(token: token, value: value)
            let amountType: SendField.AppValueType = appValue.isMaxValue ? .infinity(code: token.coin.code) : .regular(appValue: appValue)
            fields = [
                .simpleValue(title: "wallet_connect.allowance.amount".localized, value: amountType.formattedFull() ?? ""),
                .recipient(title: "approve.confirmation.spender".localized, value: spender.eip55, copyable: true, blockchainType: token.blockchainType),
            ]
        case let .outgoingEvm(to, value):
            fields = outgoingFields(token: baseToken, to: to, value: value)
        case let .outgoingEip20(to, value, token):
            fields = outgoingFields(token: token, to: to, value: value)
        case let .unknown(to, value, input, method):
            // Android SendEvmTransactionViewItemFactory.getUnknownMethodItems: method, value, to, input
            fields = []
            if let method {
                fields.append(.simpleValue(title: "send.confirmation.method".localized, value: method))
            }
            fields.append(contentsOf: outgoingFields(token: baseToken, to: to, value: value))
            if !input.isEmpty {
                fields.append(.hex(title: "send.confirmation.input".localized, value: input.toHexString()))
            }
        }

        if let nonce = evmSendData.nonce {
            fields.append(.simpleValue(title: "send.confirmation.nonce".localized, value: String(nonce)))
        }

        return [SendDataSection(fields, isMain: false)]
    }

    // Android ViewItem.Amount -> "Value" coin amount only (no fiat); ViewItem.Address -> shortened + copy
    private func outgoingFields(token: Token, to: EvmKit.Address, value: Decimal) -> [SendField] {
        [
            .value(title: "value".localized, appValue: AppValue(token: token, value: value), currencyValue: nil, formatFull: true),
            .recipient(title: "send.confirmation.to".localized, value: to.eip55, copyable: true, blockchainType: token.blockchainType),
        ]
    }
}
