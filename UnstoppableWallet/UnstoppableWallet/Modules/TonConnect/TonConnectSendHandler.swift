import BigInt
import Foundation
import MarketKit
import TonKit
import TonSwift

class TonConnectSendHandler {
    private let tonConnectManager = App.shared.tonConnectManager
    private let request: TonConnectSendTransactionRequest
    private let transferData: TransferData
    private let contract: WalletContract
    private let secretKey: Data
    let baseToken: Token
    private let converter: TonEventConverter

    init(request: TonConnectSendTransactionRequest, transferData: TransferData, contract: WalletContract, secretKey: Data, baseToken: Token, converter: TonEventConverter) {
        self.request = request
        self.transferData = transferData
        self.contract = contract
        self.secretKey = secretKey
        self.baseToken = baseToken
        self.converter = converter
    }
}

extension TonConnectSendHandler: ISendHandler {
    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var fee: Decimal?
        var transactionError: Error?
        var record: TonTransactionRecord?

        do {
            let result = try await TonKit.Kit.emulate(transferData: transferData, contract: contract, network: TonKitManager.network)

            record = converter.transactionRecord(event: result.event)
            fee = TonAdapter.amount(kitAmount: result.totalFee)
        } catch {
            transactionError = error
        }

        return SendData(record: record, fee: fee, transactionError: transactionError)
    }

    func send(data _: ISendData) async throws {
        let boc = try await TonKit.Kit.boc(transferData: transferData, contract: contract, secretKey: secretKey, network: TonKitManager.network)

        try await TonKit.Kit.send(boc: boc, contract: contract, network: TonKitManager.network)
        try await tonConnectManager.approve(request: request, boc: boc)
    }
}

extension TonConnectSendHandler {
    class SendData: ISendData {
        private let record: TonTransactionRecord?
        private let fee: Decimal?
        private let transactionError: Error?

        init(record: TonTransactionRecord?, fee: Decimal?, transactionError: Error?) {
            self.record = record
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
            var coins = [Coin?]()

            if let record {
                for action in record.actions {
                    switch action.type {
                    case let .send(value, _, _, _): coins.append(value.coin)
                    case let .receive(value, _, _): coins.append(value.coin)
                    case let .burn(value): coins.append(value.coin)
                    case let .mint(value): coins.append(value.coin)
                    case let .swap(_, _, valueIn, valueOut):
                        coins.append(valueIn.coin)
                        coins.append(valueOut.coin)
                    case .contractDeploy: ()
                    case let .contractCall(_, value, _): coins.append(value.coin)
                    case .unsupported: ()
                    }
                }
            }

            return coins.compactMap { $0 }
        }

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let tonError = transactionError as? TonConnectSendHandler.TransactionError {
                switch tonError {
                case let .insufficientTonBalance(balance):
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
            var sections = [[SendField]]()

            if let record {
                for action in record.actions {
                    var fields: [SendField]

                    switch action.type {
                    case let .send(value, to, _, comment):
                        if let token = value.token {
                            fields = [
                                .amount(
                                    title: "send.confirmation.you_send".localized,
                                    token: token,
                                    appValueType: .regular(appValue: AppValue(token: token, value: value.value)),
                                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * value.value) },
                                    type: .outgoing
                                ),
                                .address(
                                    title: "send.confirmation.to".localized,
                                    value: to,
                                    blockchainType: .ton
                                ),
                            ]

                            if let comment {
                                fields.append(.levelValue(title: "send.confirmation.comment".localized, value: comment, level: .regular))
                            }
                        } else {
                            fields = [.levelValue(title: "send.confirmation.action".localized, value: "Send", level: .regular)]
                        }

                    case let .receive(value, from, comment):
                        if let token = value.token {
                            fields = [
                                .amount(
                                    title: "send.confirmation.you_receive".localized,
                                    token: token,
                                    appValueType: .regular(appValue: AppValue(token: token, value: value.value)),
                                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * value.value) },
                                    type: .incoming
                                ),
                                .address(
                                    title: "send.confirmation.from".localized,
                                    value: from,
                                    blockchainType: .ton
                                ),
                            ]

                            if let comment {
                                fields.append(.levelValue(title: "send.confirmation.comment".localized, value: comment, level: .regular))
                            }
                        } else {
                            fields = [.levelValue(title: "send.confirmation.action".localized, value: "Receive", level: .regular)]
                        }

                    case .burn:
                        fields = [.levelValue(title: "send.confirmation.action".localized, value: "Burn", level: .regular)]

                    case .mint:
                        fields = [.levelValue(title: "send.confirmation.action".localized, value: "Mint", level: .regular)]

                    case let .swap(_, _, valueIn, valueOut):
                        if let tokenIn = valueIn.token, let tokenOut = valueOut.token {
                            fields = [
                                .amount(
                                    title: "swap.you_pay".localized,
                                    token: tokenIn,
                                    appValueType: .regular(appValue: AppValue(token: tokenIn, value: valueIn.value)),
                                    currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: valueIn.value * $0) },
                                    type: .neutral
                                ),
                                .amount(
                                    title: "swap.you_get".localized,
                                    token: tokenOut,
                                    appValueType: .regular(appValue: AppValue(token: tokenOut, value: valueOut.value)),
                                    currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: valueOut.value * $0) },
                                    type: .incoming
                                ),
                                .price(
                                    title: "swap.price".localized,
                                    tokenA: tokenIn,
                                    tokenB: tokenOut,
                                    amountA: valueIn.value,
                                    amountB: valueOut.value
                                ),
                            ]
                        } else {
                            fields = [.levelValue(title: "send.confirmation.action".localized, value: "Swap", level: .regular)]
                        }

                    case .contractDeploy:
                        fields = [.levelValue(title: "send.confirmation.action".localized, value: "Contract- Deploy", level: .regular)]

                    case .contractCall:
                        fields = [.levelValue(title: "send.confirmation.action".localized, value: "Contract Call", level: .regular)]

                    case let .unsupported(type):
                        fields = [.levelValue(title: "send.confirmation.action".localized, value: type, level: .regular)]
                    }

                    switch action.status {
                    case .failed:
                        fields.append(.levelValue(title: "send.confirmation.status".localized, value: "send.confirmation.status.failed".localized, level: .error))
                    default: ()
                    }

                    sections.append(fields)
                }
            }

            sections.append(feeFields(currency: currency, feeToken: baseToken, feeTokenRate: rates[baseToken.coin.uid]))

            return sections
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

extension TonConnectSendHandler {
    enum SendError: Error {
        case invalidAmount
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientTonBalance(balance: Decimal)
    }

    enum FactoryError: Error {
        case noAccount
        case noBaseToken
    }
}

extension TonConnectSendHandler {
    static func instance(request: TonConnectSendTransactionRequest) throws -> TonConnectSendHandler {
        guard let account = App.shared.accountManager.account(id: request.app.accountId) else {
            throw FactoryError.noAccount
        }

        let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)
        let contract = TonKitManager.contract(publicKey: publicKey)
        let address = try contract.address()

        let payloads = request.param.messages.map { message in
            TonKit.Kit.Payload(
                value: BigInt(integerLiteral: message.amount),
                recipientAddress: message.address,
                stateInit: message.stateInit,
                payload: message.payload
            )
        }

        let transferData = try TonKit.Kit.transferData(sender: address, payloads: payloads)

        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .ton, tokenType: .native)) else {
            throw FactoryError.noBaseToken
        }

        let transactionSource = TransactionSource(blockchainType: .ton, meta: nil)

        return TonConnectSendHandler(
            request: request,
            transferData: transferData,
            contract: contract,
            secretKey: secretKey,
            baseToken: baseToken,
            converter: TonEventConverter(address: address, source: transactionSource, baseToken: baseToken, coinManager: App.shared.coinManager)
        )
    }
}
