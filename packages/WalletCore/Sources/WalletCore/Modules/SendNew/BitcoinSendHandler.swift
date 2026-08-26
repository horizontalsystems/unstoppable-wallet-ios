import BitcoinCore
import Foundation
import Hodler
import MarketKit

class BitcoinSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .bitcoin(token, params) = sendData else { return nil }
        return instance(token: token, params: params)
    }

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
        _ = try await sendCapturingRef(data: data)
    }
}

extension BitcoinSendHandler: ISendHandlerRefCapturing {
    // Same broadcast path as `send`, returning the on-chain tx hash.
    func sendCapturingRef(data: ISendData) async throws -> String {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        let fullTransaction = try adapter.send(params: data.params)

        return fullTransaction.header.dataHash.hs.reversedHex
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

        func fields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
            var fields = [SendField]()

            if let memo = params.memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            if let timeLock {
                fields.append(.simpleValue(title: "send.confirmation.time_lock".localized, value: timeLock))
            }

            if rbfAllowed, !params.rbfEnabled {
                fields.append(.simpleValue(
                    title: "send.confirmation.replace_by_fee".localized,
                    value: "send.confirmation.replace_by_fee.disabled".localized
                ))
            }

            return fields
        }

        func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
            UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates)
            let fields = fields(baseToken: baseToken, currency: currency, rates: rates)
            let feeFields = feeFields(baseToken: baseToken, currency: currency, rates: rates)

            return [flow, .init(fields + feeFields, isMain: false)].compactMap { $0 }
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
