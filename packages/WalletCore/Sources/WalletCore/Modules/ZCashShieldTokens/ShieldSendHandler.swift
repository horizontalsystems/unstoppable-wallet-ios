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

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let memoText = memo.flatMap { try? Memo(string: $0) }
        let zip317MarginalFee = transactionSettings?.zcashZip317MarginalFee ?? ZcashAdapter.defaultZip317MarginalFee

        guard let proposal = try await adapter.shieldProposal(
            threshold: ZcashAdapter.minimalThreshold,
            address: recipient,
            memo: memoText,
            zip317MarginalFee: zip317MarginalFee
        ) else {
            throw SendError.cantCreateProposal
        }

        var transactionError: Error?
        let fee = proposal.totalFeeRequired().decimalValue.decimalValue
        if ZcashAdapter.minimalThreshold >= adapter.zCashBalanceData.transparent {
            transactionError = AppError.zcash(reason: .notEnough)
        }

        return SendData(
            token: token,
            amount: amount - fee,
            recipient: recipient,
            memo: memo,
            transactionError: transactionError,
            proposal: proposal,
            zip317MarginalFee: zip317MarginalFee
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try await adapter.send(proposal: data.proposal, zip317MarginalFee: data.zip317MarginalFee)
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
        let zip317MarginalFee: Zatoshi

        init(token: Token, amount: Decimal, recipient: Recipient?, memo: String?, transactionError: Error?, proposal: Proposal, zip317MarginalFee: Zatoshi) {
            self.token = token
            self.amount = amount
            self.recipient = recipient
            self.memo = memo
            self.transactionError = transactionError
            self.proposal = proposal
            self.zip317MarginalFee = zip317MarginalFee
        }

        var feeData: FeeData? {
            .zcash(fee: proposal.totalFeeRequired().decimalValue.decimalValue)
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
                cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var flowFields = [SendField]()
            flowFields.append(.amount(
                token: token,
                appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) },
            ))
            if let recipient {
                flowFields.append(
                    .selfAddress(value: recipient.stringEncoded)
                )
            }

            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            let fee = proposal.totalFeeRequired().decimalValue.decimalValue
            let appValue = AppValue(token: baseToken, value: fee)
            let currencyValue = rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) }

            return [
                .init(flowFields, isFlow: true),
                .init(fields + [
                    .fee(
                        title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                        amountData: .init(appValue: appValue, currencyValue: currencyValue)
                    ),
                ], isMain: false),
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
        guard let token = try? Core.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter else {
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
