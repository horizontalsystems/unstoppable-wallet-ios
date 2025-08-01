import Foundation
import MarketKit
import StellarKit
import stellarsdk

class StellarSendHandler {
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair
    private let token: Token
    let baseToken: Token
    private let data: StellarSendData
    private let memo: String?

    init(stellarKit: StellarKit.Kit, keyPair: KeyPair, token: Token, baseToken: Token, data: StellarSendData, memo: String?) {
        self.stellarKit = stellarKit
        self.keyPair = keyPair
        self.token = token
        self.baseToken = baseToken
        self.data = data
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
        let stellarBalance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0

        var data = data

        do {
            let baseFee = try await stellarKit.baseFee()
            var totalNativeAmount: Decimal = 0

            switch data {
            case let .payment(asset, amount, accountId):
                var amount = amount

                if asset.isNative {
                    if amount == stellarBalance {
                        amount -= baseFee
                        data = .payment(asset: asset, amount: amount, accountId: accountId)
                    }

                    totalNativeAmount += amount
                }

                let destinationAccount = try await StellarKit.Kit.account(accountId: accountId)
                let operation: stellarsdk.Operation

                if let destinationAccount {
                    guard destinationAccount.assetBalanceMap[asset] != nil else {
                        throw TransactionError.noTrustline
                    }

                    operation = try stellarKit.paymentOperation(asset: asset, destinationAccountId: accountId, amount: amount)
                } else {
                    if asset.isNative {
                        operation = try stellarKit.createAccountOperation(destinationAccountId: accountId, amount: amount)
                    } else {
                        throw TransactionError.noTrustline
                    }
                }

                operations = [operation]
                fee = baseFee
                totalNativeAmount += baseFee
            case let .changeTrust(asset, limit):
                let operation = try stellarKit.changeTrustOperation(asset: asset, limit: limit)

                operations = [operation]
                fee = baseFee
                totalNativeAmount += baseFee
            }

            if stellarBalance < totalNativeAmount {
                throw TransactionError.insufficientStellarBalance(balance: stellarBalance)
            }
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            data: data,
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
        private let data: StellarSendData
        let memo: String?
        private let fee: Decimal?
        private let transactionError: Error?
        let operations: [stellarsdk.Operation]?

        init(token: Token, data: StellarSendData, memo: String?, fee: Decimal?, transactionError: Error?, operations: [stellarsdk.Operation]?) {
            self.token = token
            self.data = data
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
                case .noTrustline:
                    title = "send.stellar.no_trustline.title".localized
                    text = "send.stellar.no_trustline.description".localized
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

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()

            switch data {
            case let .payment(_, amount, accountId):
                fields.append(contentsOf: [
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
                ])
            case let .changeTrust(asset, limit):
                let appValue = AppValue(token: token, value: limit)

                fields.append(contentsOf: [
                    .amount(
                        title: "Change Trust",
                        token: token,
                        appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                        currencyValue: appValue.isMaxValue ? nil : rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * limit) },
                        type: .neutral
                    ),
                    .address(
                        title: "Issuer",
                        value: asset.issuer ?? "",
                        blockchainType: .stellar
                    ),
                ])
            }

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [
                .init(fields),
                .init(feeFields(currency: currency, feeToken: baseToken, feeTokenRate: rates[token.coin.uid])),
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
        case noTrustline
    }
}

extension StellarSendHandler {
    static func instance(data: StellarSendData, token: Token, memo: String?) -> StellarSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native)) else {
            return nil
        }

        guard let stellarKit = Core.shared.stellarKitManager.stellarKit else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount, let keyPair = try? StellarKitManager.keyPair(accountType: account.type) else {
            return nil
        }

        return StellarSendHandler(
            stellarKit: stellarKit,
            keyPair: keyPair,
            token: token,
            baseToken: baseToken,
            data: data,
            memo: memo
        )
    }
}
