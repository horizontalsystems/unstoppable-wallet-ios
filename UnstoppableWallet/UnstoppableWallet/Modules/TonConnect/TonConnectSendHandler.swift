import BigInt
import Foundation
import MarketKit
import TonKit
import TonSwift

class TonConnectSendHandler {
    private let tonConnectManager = Core.shared.tonConnectManager
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
            let emulationResult = try await TonSendHelper.emulate(
                transferData: transferData,
                contract: contract,
                converter: converter
            )

            fee = emulationResult.fee
            record = emulationResult.record

            try await TonSendHelper.validateBalance(
                address: contract.address(),
                totalValue: emulationResult.totalValue,
                fee: TonAdapter.kitAmount(amount: emulationResult.fee)
            )
        } catch {
            transactionError = error
        }

        return SendData(record: record, fee: fee, transactionError: transactionError)
    }

    func send(data _: ISendData) async throws {
        let boc = try await TonSendHelper.send(
            transferData: transferData,
            contract: contract,
            secretKey: secretKey
        )

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

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(TonSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var sections = [SendDataSection]()

            if let record {
                for action in record.actions {
                    var fields = [SendField]()

                    switch action.type {
                    case let .send(value, to, _, comment):
                        if let token = value.token {
                            sections.append(SendDataSection([
                                .amount(
                                    token: token,
                                    appValueType: .regular(appValue: AppValue(token: token, value: value.value)),
                                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * value.value) },
                                ),
                                .address(
                                    value: to,
                                    blockchainType: .ton
                                ),
                            ], isFlow: true))

                            if let comment {
                                fields.append(.simpleValue(title: "send.confirmation.comment".localized, value: comment))
                            }
                        } else {
                            fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Send")]
                        }

                    case let .receive(value, from, comment):
                        if let token = value.token {
                            sections.append(SendDataSection([ // TODO: YOU RECEIVE not SEND
                                .amount(
                                    token: token,
                                    appValueType: .regular(appValue: AppValue(token: token, value: value.value)),
                                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * value.value) },
                                ),
                                .address(
                                    value: from,
                                    blockchainType: .ton
                                ),
                            ], isFlow: true))

                            if let comment {
                                fields.append(.simpleValue(title: "send.confirmation.comment".localized, value: comment))
                            }
                        } else {
                            fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Receive")]
                        }

                    case .burn:
                        fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Burn")]

                    case .mint:
                        fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Mint")]

                    case let .swap(_, _, valueIn, valueOut):
                        if let tokenIn = valueIn.token, let tokenOut = valueOut.token {
                            sections.append(SendDataSection([
                                .amount(
                                    token: tokenIn,
                                    appValueType: .regular(appValue: AppValue(token: tokenIn, value: valueIn.value)),
                                    currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: valueIn.value * $0) },
                                ),
                                .amount(
                                    token: tokenOut,
                                    appValueType: .regular(appValue: AppValue(token: tokenOut, value: valueOut.value)),
                                    currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: valueOut.value * $0) },
                                ),
                            ], isFlow: true))

                            fields = [
                                .price(
                                    title: "swap.price".localized,
                                    tokenA: tokenIn,
                                    tokenB: tokenOut,
                                    amountA: valueIn.value,
                                    amountB: valueOut.value
                                ),
                            ]
                        } else {
                            fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Swap")]
                        }

                    case .contractDeploy:
                        fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Contract- Deploy")]

                    case .contractCall:
                        fields = [.simpleValue(title: "send.confirmation.action".localized, value: "Contract Call")]

                    case let .unsupported(type):
                        fields = [.simpleValue(title: "send.confirmation.action".localized, value: type)]
                    }

                    switch action.status {
                    case .failed:
                        fields.append(.levelValue(title: "send.confirmation.status".localized, value: "send.confirmation.status.failed".localized, level: .error))
                    default: ()
                    }

                    sections.append(.init(fields, isMain: false))
                }
            }

            sections.append(.init(TonSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])))

            return sections
        }
    }
}

extension TonConnectSendHandler {
    enum SendError: Error {
        case invalidAmount
        case invalidData
    }

    enum FactoryError: Error {
        case noAccount
        case noBaseToken
    }
}

extension TonConnectSendHandler {
    static func instance(request: TonConnectSendTransactionRequest) throws -> TonConnectSendHandler {
        guard let account = Core.shared.accountManager.account(id: request.app.accountId) else {
            throw FactoryError.noAccount
        }

        let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)
        let contract = TonKitManager.contract(publicKey: publicKey)
        let address = try contract.address()

        let payloads = request.param.messages.map { message in
            TonKit.Kit.Payload(
                value: BigInt(integerLiteral: message.amount),
                recipientAddress: message.address,
                bounceable: message.bounceable ?? true,
                stateInit: message.stateInit,
                payload: message.payload
            )
        }

        let transferData = try TonKit.Kit.transferData(sender: address, validUntil: request.param.validUntil, payloads: payloads)

        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .ton, tokenType: .native)) else {
            throw FactoryError.noBaseToken
        }

        let transactionSource = TransactionSource(blockchainType: .ton, meta: nil)

        return TonConnectSendHandler(
            request: request,
            transferData: transferData,
            contract: contract,
            secretKey: secretKey,
            baseToken: baseToken,
            converter: TonEventConverter(address: address, source: transactionSource, baseToken: baseToken, coinManager: Core.shared.coinManager)
        )
    }
}
