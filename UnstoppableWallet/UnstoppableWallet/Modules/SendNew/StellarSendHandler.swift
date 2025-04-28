import Foundation
import MarketKit
import StellarKit
import stellarsdk

class StellarSendHandler {
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair
    private let token: Token
    let baseToken: Token
    private let asset: StellarKit.Asset
    private let amount: Decimal
    private let accountId: String
    private let memo: String?

    init(stellarKit: StellarKit.Kit, keyPair: KeyPair, token: Token, baseToken: Token, asset: StellarKit.Asset, amount: Decimal, accountId: String, memo: String?) {
        self.stellarKit = stellarKit
        self.keyPair = keyPair
        self.token = token
        self.baseToken = baseToken
        self.asset = asset
        self.amount = amount
        self.accountId = accountId
        self.memo = memo
    }
}

extension StellarSendHandler: ISendHandler {
    var expirationDuration: Int? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var fee: Decimal?
        var transactionError: Error?
        var operations: [stellarsdk.Operation]?
        let stellarBalance = stellarKit.assetBalances[.native] ?? 0

        var amount = amount

        do {
            let baseFee = try await stellarKit.baseFee()

            if token.type.isNative, amount == stellarBalance {
                amount -= baseFee
            }

            let _operations = try stellarKit.paymentOperations(asset: asset, destinationAccountId: accountId, amount: amount)
            let _fee = baseFee * Decimal(_operations.count)

            fee = _fee
            operations = _operations

            if token.type.isNative {
                if amount + _fee > stellarBalance {
                    throw TransactionError.insufficientStellarBalance(balance: stellarBalance)
                }
            } else {
                if stellarBalance < _fee {
                    throw TransactionError.insufficientStellarBalance(balance: stellarBalance)
                }
            }
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            amount: amount,
            accountId: keyPair.accountId,
            memo: memo,
            fee: fee,
            transactionError: transactionError,
            operations: operations
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData, let operations = data.operations else {
            throw SendError.invalidData
        }

        let memo = data.memo.map { Memo.text($0) } ?? Memo.none

        _ = try await StellarKit.Kit.send(operations: operations, memo: memo, keyPair: keyPair, testNet: false)
    }
}

extension StellarSendHandler {
    class SendData: ISendData {
        private let token: Token
        private let amount: Decimal
        let accountId: String
        let memo: String?
        private let fee: Decimal?
        private let transactionError: Error?
        let operations: [stellarsdk.Operation]?

        init(token: Token, amount: Decimal, accountId: String, memo: String?, fee: Decimal?, transactionError: Error?, operations: [stellarsdk.Operation]?) {
            self.token = token
            self.amount = amount
            self.accountId = accountId
            self.memo = memo
            self.fee = fee
            self.transactionError = transactionError
            self.operations = operations
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

            if let stellarError = transactionError as? StellarSendHandler.TransactionError {
                switch stellarError {
                case let .insufficientStellarBalance(balance):
                    let appValue = AppValue(token: feeToken, value: balance)
                    let balanceString = appValue.formattedShort()

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
                }
            } else {
                title = "ethereum_transaction.error.title".localized
                text = transactionError.convertedError.smartDescription
            }

            return CautionNew(title: title, text: text, type: .error)
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
                .address(
                    title: "send.confirmation.to".localized,
                    value: accountId,
                    blockchainType: .stellar
                ),
            ]

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [
                fields,
                feeFields(currency: currency, feeToken: baseToken, feeTokenRate: rates[token.coin.uid]),
            ]
        }

        private func feeFields(currency: Currency, feeToken: Token, feeTokenRate: Decimal?) -> [SendField] {
            var viewItems = [SendField]()

            if let fee {
                let appValue = AppValue(token: feeToken, value: fee)
                let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

                viewItems.append(
                    .value(
                        title: "fee_settings.network_fee".localized,
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                        appValue: appValue,
                        currencyValue: currencyValue,
                        formatFull: true
                    )
                )
            }

            return viewItems
        }
    }
}

extension StellarSendHandler {
    enum SendError: Error {
        case invalidAmount
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientStellarBalance(balance: Decimal)
    }
}

extension StellarSendHandler {
    static func instance(token: Token, amount: Decimal, accountId: String, memo: String?) -> StellarSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? StellarAdapter else {
            return nil
        }

        guard let stellarKit = App.shared.stellarKitManager.stellarKit else {
            return nil
        }

        guard let account = App.shared.accountManager.activeAccount, let keyPair = try? StellarKitManager.keyPair(accountType: account.type) else {
            return nil
        }

        return StellarSendHandler(
            stellarKit: stellarKit,
            keyPair: keyPair,
            token: token,
            baseToken: baseToken,
            asset: adapter.asset,
            amount: amount,
            accountId: accountId,
            memo: memo
        )
    }
}
