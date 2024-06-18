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
        SendData(
            token: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            fee: adapter.fee
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        _ = try await adapter.send(amount: data.amount, address: data.recipient, memo: data.memo.flatMap { try? Memo(string: $0) })
    }
}

extension ZcashSendHandler {
    class SendData: ISendData {
        private let token: Token
        let amount: Decimal
        let recipient: Recipient
        let memo: String?
        private let fee: Decimal

        init(token: Token, amount: Decimal, recipient: Recipient, memo: String?, fee: Decimal) {
            self.token = token
            self.amount = amount
            self.recipient = recipient
            self.memo = memo
            self.fee = fee
        }

        var feeData: FeeData? {
            nil
        }

        var canSend: Bool {
            true
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func cautions(baseToken _: Token) -> [CautionNew] {
            []
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            var fields: [SendField] = [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    coinValueType: .regular(coinValue: CoinValue(kind: .token(token: token), value: amount)),
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) },
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: recipient.stringEncoded,
                    blockchainType: .zcash
                ),
            ]

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [
                fields,
                [
                    .value(
                        title: "fee_settings.network_fee".localized,
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                        coinValue: CoinValue(kind: .token(token: baseToken), value: fee),
                        currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                        formatFull: true
                    ),
                ],
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
        guard let token = try? App.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? ISendZcashAdapter else {
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
