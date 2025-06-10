import Foundation
import MarketKit
import ZcashLightClientKit

class ShieldSendHandler {
    private let token: Token
    private let amount: Decimal
    private let recipient: Recipient?
    private let memo: String?
    private var adapter: ZcashAdapter

    init(token: Token, amount: Decimal, recipient: Recipient?, memo: String?, adapter: ZcashAdapter) {
        self.token = token
        self.amount = amount
        self.recipient = recipient
        self.memo = memo
        self.adapter = adapter
    }
}

extension ShieldSendHandler: ISendHandler {
    var baseToken: Token {
        token
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let memoText = memo.flatMap { try? Memo(string: $0) }

        guard let proposal = try await adapter.shieldProposal(threshold: ZcashAdapter.minimalThreshold, address: recipient, memo: memoText) else {
            throw SendError.cantCreateProposal
        }

        var transactionError: Error?
        let fee = proposal.totalFeeRequired().decimalValue.decimalValue
        if ZcashAdapter.minimalThreshold >= adapter.zcashBalanceData.transparent {
            transactionError = AppError.zcash(reason: .notEnough)
        }

        return SendData(
            token: token,
            amount: amount - fee,
            recipient: recipient,
            memo: memo,
            transactionError: transactionError,
            proposal: proposal
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try await adapter.send(proposal: data.proposal)
    }
}

extension ShieldSendHandler {
    enum SendError: Error {
        case invalidData
        case cantCreateProposal
    }
}

extension ShieldSendHandler {
    class SendData: ISendData {
        private let token: Token
        let amount: Decimal
        let recipient: Recipient?
        let memo: String?
        var transactionError: Error?
        let proposal: Proposal

        init(token: Token, amount: Decimal, recipient: Recipient?, memo: String?, transactionError: Error?, proposal: Proposal) {
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

        func cautions(baseToken: Token) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            var fields: [SendField] = [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) },
                    type: .neutral
                ),
                .note(iconName: "arrow_return_24", title: "send.confirmation.send_to_own".localized),
            ]
            if let recipient {
                fields.append(
                    .address(
                        title: "send.confirmation.from".localized,
                        value: recipient.stringEncoded,
                        blockchainType: .zcash
                    )
                )
            }

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            let fee = proposal.totalFeeRequired().decimalValue.decimalValue

            return [
                fields,
                [
                    .value(
                        title: "fee_settings.network_fee".localized,
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                        appValue: AppValue(token: baseToken, value: fee),
                        currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                        formatFull: true
                    ),
                ],
            ]
        }

        func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let error = transactionError as? AppError {
                switch error {
                case .zcash:
                    title = error.localizedDescription
                    text = "fee_settings.errors.insufficient_balance.info".localized(feeToken.coin.code)

                default:
                    title = "Send Info error"
                    text = "Send Info error description"
                }
            } else {
                title = "alert.error".localized
                text = transactionError.convertedError.smartDescription
            }

            return CautionNew(title: title, text: text, type: .error)
        }
    }
}

extension ShieldSendHandler {
    static func instance(amount: Decimal, recipient: Recipient?, memo: String?) -> ShieldSendHandler? {
        guard let token = try? App.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? ZcashAdapter else {
            return nil
        }

        return ShieldSendHandler(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            adapter: adapter
        )
    }
}
