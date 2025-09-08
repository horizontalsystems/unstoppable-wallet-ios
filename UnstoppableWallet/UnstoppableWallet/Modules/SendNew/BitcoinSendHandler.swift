import BitcoinCore
import Foundation
import Hodler
import MarketKit

class BitcoinSendHandler {
    private let token: Token
    private var params: SendParameters
    private var adapter: BitcoinBaseAdapter

    private let blockchainManager = Core.shared.btcBlockchainManager

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
            rbfAllowed: blockchainManager.transactionRbfAllowed(blockchainType: token.blockchainType),
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
        let rbfAllowed: Bool

        private var timeLock: String? {
            if let data = params.pluginData[HodlerPlugin.id] as? HodlerData {
                return HodlerPlugin.LockTimeInterval.title(lockTimeInterval: data.lockTimeInterval)
            }

            return nil
        }

        init(token: Token, params: SendParameters, rbfAllowed: Bool, transactionError: Error?, satoshiPerByte: Int?, feeData: BitcoinFeeData?) {
            self.token = token
            self.params = params
            self.rbfAllowed = rbfAllowed
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

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            guard let toAddress = params.address, let value = params.value else {
                return []
            }

            let decimalValue = baseToken.decimalValue(value: value)
            let appValue = AppValue(token: baseToken, value: -decimalValue)
            let rate = rates[baseToken.coin.uid]

            var sendFields: [SendField] = [
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
            ]

            if let memo = params.memo {
                sendFields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo, copying: false))
            }

            if let timeLock {
                sendFields.append(.simpleValue(icon: "lock", title: "send.confirmation.time_lock".localized, value: timeLock, copying: false))
            }

            if rbfAllowed, !params.rbfEnabled {
                sendFields.append(.simpleValue(
                    title: "send.confirmation.replace_by_fee".localized,
                    value: "send.confirmation.replace_by_fee.disabled".localized,
                    copying: false
                )
                )
            }

            let feeSection: SendDataSection = .init(
                feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rate)
            )

            return [
                .init(sendFields),
                feeSection,
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
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? BitcoinBaseAdapter else {
            return nil
        }

        return BitcoinSendHandler(
            token: token,
            params: params,
            adapter: adapter
        )
    }
}
