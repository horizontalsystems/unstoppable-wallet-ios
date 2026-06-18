import Foundation
import MarketKit
import ZcashLightClientKit

class ZcashSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        switch sendData {
        case let .zcash(amount, recipient, memo):
            return instance(amount: amount, recipient: recipient, memo: memo)
        case let .zcashResend(amount, recipient, memo, initialTransactionSettings):
            return instance(amount: amount, recipient: recipient, memo: memo, initialTransactionSettings: initialTransactionSettings)
        default:
            return nil
        }
    }

    private let token: Token
    private let amount: Decimal
    private let recipient: Recipient
    private let memo: String?
    let initialTransactionSettings: InitialTransactionSettings?
    private var adapter: ZcashAdapter

    init(token: Token, amount: Decimal, recipient: Recipient, memo: String?, adapter: ZcashAdapter, initialTransactionSettings: InitialTransactionSettings? = nil) {
        self.token = token
        self.amount = amount
        self.recipient = recipient
        self.memo = memo
        self.adapter = adapter
        self.initialTransactionSettings = initialTransactionSettings
    }
}

extension ZcashSendHandler: ISendHandler {
    var baseToken: Token {
        token
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let memoText = memo.flatMap { try? Memo(string: $0) }
        let zip317MarginalFee = transactionSettings?.zcashZip317MarginalFee ?? ZcashAdapter.defaultZip317MarginalFee

        var transactionError: Error?
        var proposal: Proposal?
        do {
            proposal = try await adapter.sendProposal(
                amount: amount,
                address: recipient,
                memo: memoText,
                zip317MarginalFee: zip317MarginalFee
            )
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            transactionError: transactionError,
            proposal: proposal,
            zip317MarginalFee: zip317MarginalFee
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData, let proposal = data.proposal else {
            throw SendError.invalidData
        }

        try await adapter.send(proposal: proposal, zip317MarginalFee: data.zip317MarginalFee)
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
        let zip317MarginalFee: Zatoshi

        init(token: Token, amount: Decimal, recipient: Recipient, memo: String?, transactionError: Error?, proposal: Proposal?, zip317MarginalFee: Zatoshi) {
            self.token = token
            self.amount = amount
            self.recipient = recipient
            self.memo = memo
            self.transactionError = transactionError
            self.proposal = proposal
            self.zip317MarginalFee = zip317MarginalFee
        }

        var feeData: FeeData? {
            .zcash(fee: proposal?.totalFeeRequired().decimalValue.decimalValue)
        }

        var canSend: Bool {
            proposal != nil && transactionError == nil
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
                        title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
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
    static func instance(amount: Decimal, recipient: Recipient, memo: String?, initialTransactionSettings: InitialTransactionSettings? = nil) -> ZcashSendHandler? {
        guard let token = try? Core.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter else {
            return nil
        }

        return ZcashSendHandler(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            adapter: adapter,
            initialTransactionSettings: initialTransactionSettings
        )
    }
}
