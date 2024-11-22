import BitcoinCore
import Foundation
import MarketKit

class BitcoinSendHandler {
    private let token: Token
    private var params: SendParameters
    private var adapter: BitcoinBaseAdapter

    init(token: Token, params: SendParameters, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.params = params
        self.adapter = adapter
    }
}

extension BitcoinSendHandler: ISendHandler {
    var baseToken: MarketKit.Token {
        token
    }

    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let satoshiPerByte = transactionSettings?.satoshiPerByte
        var feeData: BitcoinFeeData?
        var transactionError: Error?
        let params = params.copy()

        if let satoshiPerByte {
            params.feeRate = satoshiPerByte

            let balance = adapter.balanceData.available
            let decimalValue = params.value.map { Decimal($0) / adapter.coinRate }
            if decimalValue == balance {
                params.value = adapter.convertToSatoshi(value: adapter.availableBalance(params: params))
            }

            do {
                let sendInfo = try adapter.sendInfo(params: params)
                feeData = .init(fee: sendInfo.fee)
            } catch {
                transactionError = error
            }
        }

        return SendData(
            token: token,
            params: params,
            transactionError: transactionError,
            satoshiPerByte: satoshiPerByte,
            feeData: feeData
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }
        
        try adapter.send(params: data.params)
    }
}

extension BitcoinSendHandler {
    class SendData: BaseSendBtcData, ISendData {
        private let token: Token
        private let transactionError: Error?
        let params: SendParameters

        init(token: Token, params: SendParameters, transactionError: Error?, satoshiPerByte: Int?, feeData: BitcoinFeeData?) {
            self.token = token
            self.params = params
            self.transactionError = transactionError

            super.init(satoshiPerByte: satoshiPerByte, fee: feeData?.fee)
        }

        var feeData: FeeData? {
            fee.map { .bitcoin(bitcoinFeeData: BitcoinFeeData(fee: $0)) }
        }

        var canSend: Bool {
            fee != nil && transactionError == nil
        }

        var customSendButtonTitle: String? {
            nil
        }

        var rateCoins: [MarketKit.Coin] {
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
            guard let toAddress = params.address, let value = params.value else {
                return []
            }

            let decimalValue = baseToken.decimalValue(value: value)
            let appValue = AppValue(token: baseToken, value: -decimalValue)
            let rate = rates[baseToken.coin.uid]

            return [
                [
                    .amount(
                        title: "send.confirmation.you_send".localized,
                        token: baseToken,
                        appValueType: .regular(appValue: appValue),
                        currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * decimalValue) },
                        type: .neutral
                    ),
                    .address(
                        title: "send.confirmation.to".localized,
                        value: toAddress,
                        blockchainType: baseToken.blockchainType
                    ),
                ],
                feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rate),
            ]
        }
    }
}

extension BitcoinSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension BitcoinSendHandler {
    static func instance(token: Token, params: SendParameters) -> BitcoinSendHandler? {
        guard let adapter = App.shared.adapterManager.adapter(for: token) as? BitcoinBaseAdapter else {
            return nil
        }

        return BitcoinSendHandler(
            token: token,
            params: params,
            adapter: adapter
        )
    }
}
