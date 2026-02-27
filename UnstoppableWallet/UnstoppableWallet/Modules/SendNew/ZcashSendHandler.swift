import Foundation
import MarketKit
import ZcashLightClientKit

class ZcashSendHandler {
    private let token: Token
    private let amount: Decimal
    private let recipient: Recipient
    private let memo: String?
    private var adapter: ISendZcashAdapter

    init(token: Token, amount: Decimal, recipient: Recipient, memo: String?, adapter: ISendZcashAdapter) {
        self.token = token
        self.amount = amount
        self.recipient = recipient
        self.memo = memo
        self.adapter = adapter
    }
}

extension ZcashSendHandler: ISendHandler {
    var baseToken: Token {
        token
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let memoText = memo.flatMap { try? Memo(string: $0) }

        var transactionError: Error?
        var proposal: Proposal?
        do {
            proposal = try await adapter.sendProposal(amount: amount, address: recipient, memo: memoText)
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            transactionError: transactionError,
            proposal: proposal
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData, let proposal = data.proposal else {
            throw SendError.invalidData
        }

        try await adapter.send(proposal: proposal)
    }
}

extension ZcashSendHandler {
    class SendData: ISendData {
        private let token: Token
        let amount: Decimal
        let recipient: Recipient
        let memo: String?
        var transactionError: Error?
        let proposal: Proposal?

        init(token: Token, amount: Decimal, recipient: Recipient, memo: String?, transactionError: Error?, proposal: Proposal?) {
            self.token = token
            self.amount = amount
            self.recipient = recipient
            self.memo = memo
            self.transactionError = transactionError
            self.proposal = proposal
        }

        var feeData: FeeData? {
            nil
        }

        var canSend: Bool {
            transactionError == nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func flowSection(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            let appValue = AppValue(token: baseToken, value: amount)
            let rate = rates[baseToken.coin.uid]

            let from = SendField.amount(
                token: baseToken,
                appValueType: .regular(appValue: appValue),
                currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * amount) },
            )

            let to = SendField.address(
                value: recipient.stringEncoded,
                blockchainType: .zcash
            )

            return .init([from, to], isFlow: true)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            var feeFields = [SendField]()
            if let proposal {
                let fee = proposal.totalFeeRequired().decimalValue.decimalValue
                let appValue = AppValue(token: baseToken, value: fee)
                let currencyValue = rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) }

                feeFields.append(
                    .fee(
                        title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                        amountData: .init(appValue: appValue, currencyValue: currencyValue)
                    )
                )
            }

            return [
                flowSection(baseToken: baseToken, currency: currency, rates: rates),
                .init(fields + feeFields, isMain: false),
            ]
        }
    }
}

extension ZcashSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension ZcashSendHandler {
    static func instance(amount: Decimal, recipient: Recipient, memo: String?) -> ZcashSendHandler? {
        guard let token = try? Core.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendZcashAdapter else {
            return nil
        }

        return ZcashSendHandler(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            adapter: adapter
        )
    }
}
