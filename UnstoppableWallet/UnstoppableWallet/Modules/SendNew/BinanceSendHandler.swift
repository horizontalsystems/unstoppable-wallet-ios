import Foundation
import MarketKit

class BinanceSendHandler {
    let baseToken: Token
    private let token: Token
    private let amount: Decimal
    private let address: String
    private let memo: String?
    private var adapter: ISendBinanceAdapter

    init(baseToken: Token, token: Token, amount: Decimal, address: String, memo: String?, adapter: ISendBinanceAdapter) {
        self.baseToken = baseToken
        self.token = token
        self.amount = amount
        self.address = address
        self.memo = memo
        self.adapter = adapter
    }
}

extension BinanceSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        SendData(
            token: token,
            amount: amount,
            address: address,
            memo: memo,
            fee: adapter.fee
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        _ = try await adapter.send(amount: data.amount, address: data.address, memo: data.memo)
    }
}

extension BinanceSendHandler {
    class SendData: ISendData {
        private let token: Token
        let amount: Decimal
        let address: String
        let memo: String?
        private let fee: Decimal

        init(token: Token, amount: Decimal, address: String, memo: String?, fee: Decimal) {
            self.token = token
            self.amount = amount
            self.address = address
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

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[TransactionField]] {
            var fields: [TransactionField] = [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    appValue: AppValue(token: token, value: amount),
                    rateValue: CurrencyValue(currency: currency, value: rates[token.coin.uid]),
                    type: .neutral,
                    hidden: false
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: address,
                    blockchainType: .binanceChain
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
                        appValue: AppValue(token: baseToken, value: fee),
                        currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                        formatFull: true
                    ),
                ],
            ]
        }
    }
}

extension BinanceSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension BinanceSendHandler {
    static func instance(token: Token, amount: Decimal, address: String, memo: String?) -> BinanceSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .binanceChain, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? ISendBinanceAdapter else {
            return nil
        }

        return BinanceSendHandler(
            baseToken: baseToken,
            token: token,
            amount: amount,
            address: address,
            memo: memo,
            adapter: adapter
        )
    }
}
