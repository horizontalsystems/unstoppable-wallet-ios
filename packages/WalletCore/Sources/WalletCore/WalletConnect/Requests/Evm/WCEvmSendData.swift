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
        let amountData = evmSendData.evmFeeData?.totalAmountData(gasPrice: evmSendData.gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
        return [.fee(title: ComponentInformedTitle("send.confirmation.fee".localized, info: .fee), amountData: amountData)]
    }

    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
        evmSendData.cautions(baseToken: baseToken, currency: currency, rates: rates)
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
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
        default:
            fields = decoration.flowSection(baseToken: baseToken, currency: currency, rates: rates)?.fields ?? []
            fields.append(contentsOf: decoration.fields(baseToken: baseToken, currency: currency, rates: rates))
        }

        if let nonce = evmSendData.nonce {
            fields.append(.simpleValue(title: "send.confirmation.nonce".localized, value: String(nonce)))
        }

        return [SendDataSection(fields, isMain: false)]
    }
}
