import Foundation
import MarketKit
import XrpKit

class XrpSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .xrp(token, data, memo, destinationTag) = sendData else { return nil }
        return instance(token: token, data: data, memo: memo, destinationTag: destinationTag)
    }

    private let signer: XrpKit.Signer
    private let token: Token
    let baseToken: Token
    private let adapter: ISendXrpAdapter & IBalanceAdapter
    private let data: XrpSendData
    private let memo: String?
    private let destinationTag: UInt32?

    init(signer: XrpKit.Signer, token: Token, baseToken: Token, adapter: ISendXrpAdapter & IBalanceAdapter, data: XrpSendData, memo: String?, destinationTag: UInt32?) {
        self.signer = signer
        self.token = token
        self.baseToken = baseToken
        self.adapter = adapter
        self.data = data
        self.memo = memo
        self.destinationTag = destinationTag
    }
}

extension XrpSendHandler: ISendHandler {
    var expirationDuration: Int? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fee = adapter.fee
        var transactionError: Error?

        // the fee is always paid in XRP on top of the amount; spendable XRP already excludes the reserve
        let availableXrp = adapter.availableXrpBalance
        switch data {
        case let .payment(amount, _):
            if token.type.isNative {
                if amount + fee > availableXrp {
                    transactionError = TransactionError.insufficientXrpBalance(balance: availableXrp)
                }
            } else if amount > adapter.balanceData.available {
                transactionError = TransactionError.insufficientTokenBalance
            } else if fee > availableXrp {
                transactionError = TransactionError.insufficientXrpBalance(balance: availableXrp)
            }
        case .trustSet:
            // the new object also locks one owner reserve increment
            let ownerReserve = Core.shared.xrpKitManager.xrpKit?.ownerReserve ?? 0
            if fee + ownerReserve > availableXrp {
                transactionError = TransactionError.insufficientXrpBalance(balance: availableXrp)
            }
        }

        return SendData(token: token, data: data, memo: memo, destinationTag: destinationTag, fee: fee, transactionError: transactionError)
    }

    func send(data: ISendData) async throws {
        _ = try await sendCapturingRef(data: data)
    }
}

extension XrpSendHandler: ISendHandlerRefCapturing {
    // Same broadcast path as `send`, returning the on-chain tx hash.
    func sendCapturingRef(data: ISendData) async throws -> String {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        switch data.data {
        case let .payment(amount, address):
            return try await adapter.send(amount: amount, address: address, destinationTag: data.destinationTag, memo: data.memo, signer: signer)
        case let .trustSet(currency, issuer, limit):
            return try await adapter.setTrustLine(currency: currency, issuer: issuer, limit: limit, signer: signer)
        }
    }
}

extension XrpSendHandler {
    class SendData: ISendData {
        let token: Token
        let data: XrpSendData
        let memo: String?
        let destinationTag: UInt32?
        private let fee: Decimal
        private let transactionError: Error?

        init(token: Token, data: XrpSendData, memo: String?, destinationTag: UInt32?, fee: Decimal, transactionError: Error?) {
            self.token = token
            self.data = data
            self.memo = memo
            self.destinationTag = destinationTag
            self.fee = fee
            self.transactionError = transactionError
        }

        var feeData: FeeData? {
            nil
        }

        var canSend: Bool {
            transactionError == nil
        }

        var customSendButtonTitle: String? {
            nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let xrpError = transactionError as? XrpSendHandler.TransactionError {
                switch xrpError {
                case let .insufficientXrpBalance(balance):
                    let balanceString = AppValue(token: feeToken, value: balance).formattedShort()
                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
                case .insufficientTokenBalance:
                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "swap.insufficient_balance".localized
                }
            } else {
                title = "ethereum_transaction.error.title".localized
                text = transactionError.convertedError.smartDescription
            }

            return CautionNew(title: title, text: text, type: .error)
        }

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            guard let transactionError else {
                return []
            }
            return [caution(transactionError: transactionError, feeToken: baseToken)]
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            switch data {
            case let .payment(amount, address):
                return .init([
                    .amount(
                        token: token,
                        appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                        currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }
                    ),
                    .address(
                        value: address,
                        blockchainType: .xrp
                    ),
                ], isFlow: true)
            case let .trustSet(_, issuer, limit):
                let appValue = AppValue(token: token, value: limit)
                return .init([
                    .amount(
                        token: token,
                        appValueType: limit == XrpKit.Kit.defaultTrustLimit ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                        currencyValue: nil
                    ),
                    .address(
                        value: issuer,
                        blockchainType: .xrp
                    ),
                ], isFlow: true)
            }
        }

        func fields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
            var fields = [SendField]()

            if let destinationTag {
                fields.append(.simpleValue(title: "send.xrp.destination_tag".localized, value: String(destinationTag)))
            }
            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            return fields
        }

        func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
            let appValue = AppValue(token: baseToken, value: fee)
            let currencyValue = rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) }

            return [
                .fee(
                    title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                    amountData: .init(appValue: appValue, currencyValue: currencyValue)
                ),
            ]
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates)
            let fields = fields(baseToken: baseToken, currency: currency, rates: rates)
            let feeFields = feeFields(baseToken: baseToken, currency: currency, rates: rates)

            return [flow, .init(fields + feeFields, isMain: false)]
        }
    }
}

extension XrpSendHandler {
    enum SendError: Error {
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientXrpBalance(balance: Decimal)
        case insufficientTokenBalance
    }
}

extension XrpSendHandler {
    static func instance(token: Token, data: XrpSendData, memo: String?, destinationTag: UInt32?) -> XrpSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .xrp, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendXrpAdapter & IBalanceAdapter else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount,
              let signer = try? XrpKitManager.signer(accountType: account.type)
        else {
            return nil
        }

        return XrpSendHandler(signer: signer, token: token, baseToken: baseToken, adapter: adapter, data: data, memo: memo, destinationTag: destinationTag)
    }
}
