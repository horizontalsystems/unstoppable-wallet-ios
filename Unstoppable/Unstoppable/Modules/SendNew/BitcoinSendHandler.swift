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
        var fee: Decimal?
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
                fee = sendInfo.fee
            } catch {
                transactionError = error
            }
        }

        return SendData(
            token: token,
            params: params,
            rbfAllowed: blockchainManager.transactionRbfAllowed(blockchainType: token.blockchainType),
            transactionError: transactionError,
            fee: fee
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
    class SendData: ISendData {
        private let token: Token
        private let transactionError: Error?
        let params: SendParameters
        let rbfAllowed: Bool
        private let fee: Decimal?

        private var timeLock: String? {
            if let data = params.pluginData[HodlerPlugin.id] as? HodlerData {
                return HodlerPlugin.LockTimeInterval.title(lockTimeInterval: data.lockTimeInterval)
            }

            return nil
        }

        init(token: Token, params: SendParameters, rbfAllowed: Bool, transactionError: Error?, fee: Decimal?) {
            self.token = token
            self.params = params
            self.rbfAllowed = rbfAllowed
            self.transactionError = transactionError
            self.fee = fee
        }

        var feeData: FeeData? {
            .bitcoin(params: params)
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

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func flowSection(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection? {
            guard let toAddress = params.address, let value = params.value else {
                return nil
            }

            let decimalValue = baseToken.decimalValue(value: value)
            let appValue = AppValue(token: baseToken, value: -decimalValue)
            let rate = rates[baseToken.coin.uid]

            let from = SendField.amount(
                token: baseToken,
                appValueType: .regular(appValue: appValue),
                currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * decimalValue) },
            )

            let to = SendField.address(
                value: toAddress,
                blockchainType: baseToken.blockchainType
            )

            return .init([from, to], isFlow: true)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var sections = [SendDataSection]()
            if let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates) {
                sections.append(flow)
            }

            var sendFields = [SendField]()
            let rate = rates[baseToken.coin.uid]

            if let memo = params.memo {
                sendFields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            if let timeLock {
                sendFields.append(.simpleValue(title: "send.confirmation.time_lock".localized, value: timeLock))
            }

            if rbfAllowed, !params.rbfEnabled {
                sendFields.append(.simpleValue(
                    title: "send.confirmation.replace_by_fee".localized,
                    value: "send.confirmation.replace_by_fee.disabled".localized
                ))
            }

            sendFields.append(contentsOf: UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: rate))
            sections.append(.init(sendFields, isMain: false))

            return sections
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
