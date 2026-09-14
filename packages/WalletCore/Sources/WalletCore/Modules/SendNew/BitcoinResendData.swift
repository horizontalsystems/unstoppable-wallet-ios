import BitcoinCore
import Foundation
import Hodler
import MarketKit

struct BitcoinResendData: ISendData {
    let record: BitcoinOutgoingTransactionRecord
    let type: ResendTransactionType
    var recommendedFee: Int? = nil
    var replacement: ReplacementTransaction? = nil
    var transactionError: Error? = nil

    var feeData: FeeData? { nil }
    var canSend: Bool { transactionError == nil && replacement != nil }
    var rateCoins: [Coin] { record.value.coin.map { [$0] } ?? [] }
    var customSendButtonTitle: String? {
        (type == .speedUp ? "send.confirmation.slide_to_resend" : "send.confirmation.slide_to_cancel").localized
    }

    var replacedTransactionCount: Int {
        replacement?.replacedTransactionHashes.count ?? 0
    }

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        if let transactionError {
            return [UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        }
        if let recommendedFee, let fee = record.fee?.value, canSend,
           fee < Decimal(recommendedFee) / pow(10, baseToken.decimals)
        {
            return [.init(title: "fee_settings.warning.risk_of_getting_stuck".localized,
                          text: "fee_settings.warning.risk_of_getting_stuck.info".localized, type: .warning)]
        }
        return []
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        let amount = abs(record.value.value)
        let amountFields: [SendField] = [
            SendField(SimpleValueField(
                icon: "arrow_medium_main_up_right_20",
                title: ComponentText(text: "send.confirmation.you_send".localized, colorStyle: .primary),
                value: ComponentText(text: baseToken.coin.name, colorStyle: .secondary), isPrimary: true
            )),
            .amount(token: baseToken, appValueType: .regular(appValue: AppValue(token: baseToken, value: amount)),
                    currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }),
        ]
        var fields = [SendField]()
        if let address = record.to {
            fields.append(.recipient(title: (record.sentToSelf ? "send.confirmation.own" : "send.confirmation.to").localized,
                                     value: address, copyable: true, blockchainType: baseToken.blockchainType))
        }
        if let memo = record.memo {
            fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
        }
        if let lockInfo = record.lockInfo {
            fields.append(.simpleValue(icon: "lock_filled", title: "send.confirmation.time_lock".localized,
                                       value: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: lockInfo.lockTimeInterval)))
        }
        fields.append(.simpleValue(title: "send.confirmation.replaced_transactions".localized, value: "\(replacedTransactionCount)"))
        let fee = canSend ? record.fee?.value : nil
        let feeField = SendField(FeeField(
            title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
            amountData: UtxoSendHelper.amountData(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid]),
            initialFlipped: true
        ))
        return [
            .init(amountFields, isFlow: true),
            .init(fields, isMain: false),
            .init([feeField], isMain: false),
        ]
    }
}
