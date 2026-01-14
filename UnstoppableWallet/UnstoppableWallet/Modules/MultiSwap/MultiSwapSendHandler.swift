import BigInt
import Combine
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapSendHandler {
    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let adapterManager = Core.shared.adapterManager
    private let tronKitManager = Core.shared.tronAccountManager.tronKitManager
    private let mevProtectionHelper = MevProtectionHelper()

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: IMultiSwapProvider

    private var slippage = MultiSwapSlippage.default
    private var recipient: String?

    private let refreshSubject = PassthroughSubject<Void, Never>()

    init(baseToken: Token, tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider) {
        self.baseToken = baseToken
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider
    }
}

extension MultiSwapSendHandler: ISendHandler {
    var syncingText: String? {
        "swap.confirmation.quoting".localized
    }

    var expirationDuration: Int? {
        15
    }

    var menuItems: [SendMenuItem] {
        var menuItems = [SendMenuItem]()

        if provider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut) {
            menuItems.append(
                .init(label: "swap.confirmation.slippage_tolerance".localized) { [weak self] in
                    guard let self else {
                        return
                    }

                    Coordinator.shared.present { _ in
                        MultiSwapSlippageView(slippage: self.slippage) { [weak self] slippage in
                            self?.slippage = slippage
                            self?.refreshSubject.send()
                        }
                    }
                }
            )
        }

        menuItems.append(
            .init(label: "swap.confirmation.set_recipient".localized) { [weak self] in
                guard let self else {
                    return
                }

                Coordinator.shared.present { _ in
                    MultiSwapRecipientView(address: self.recipient, token: self.tokenOut) { [weak self] recipient in
                        self?.recipient = recipient
                        self?.refreshSubject.send()
                    }
                }
            }
        )

        return menuItems
    }

    var refreshPublisher: AnyPublisher<Void, Never>? {
        refreshSubject.eraseToAnyPublisher()
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let quote = try await provider.confirmationQuote(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recipient: recipient,
            transactionSettings: transactionSettings
        )

        let otherSections: [SendDataSection] = [mevProtectionHelper.section(tokenIn: tokenIn)].compactMap { $0 }

        return SendData(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote, otherSections: otherSections)
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        if let quote = data.quote as? EvmSwapFinalQuote {
            guard let transactionData = quote.transactionData else {
                throw SendError.invalidTransactionData
            }

            guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
                throw SendError.noGasLimit
            }

            guard let gasPrice = quote.gasPrice else {
                throw SendError.noGasPrice
            }

            guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
                throw SendError.noEvmKitWrapper
            }

            _ = try await evmKitWrapper.send(
                transactionData: transactionData,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                privateSend: mevProtectionHelper.isActive,
                nonce: quote.nonce
            )
        } else if let quote = data.quote as? UtxoSwapFinalQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter else {
                throw SendError.noBitcoinAdapter
            }

            guard let sendParameters = quote.sendParameters else {
                throw SendError.noSendParameters
            }

            try adapter.send(params: sendParameters)
        } else if let quote = data.quote as? ZcashSwapFinalQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
                throw SendError.noZcashAdapter
            }

            guard let proposal = quote.proposal else {
                throw SendError.noProposal
            }

            try await adapter.send(proposal: proposal)
        } else if let quote = data.quote as? TonSwapFinalQuote {
            guard let account = Core.shared.accountManager.activeAccount else {
                throw SendError.noTonAdapter
            }

            let (publicKey, secretKey) = try TonKitManager.keyPair(accountType: account.type)
            let contract = TonKitManager.contract(publicKey: publicKey)

            let transferData = try TonSendHelper.transferData(
                param: quote.transactionParam,
                contract: contract
            )

            _ = try await TonSendHelper.send(
                transferData: transferData,
                contract: contract,
                secretKey: secretKey
            )
        } else if let quote = data.quote as? TronSwapFinalQuote {
            guard let tronKitWrapper = tronKitManager.tronKitWrapper else {
                throw SendError.noTronKitWrapper
            }

            _ = try await tronKitWrapper.send(createdTranaction: quote.createdTransaction)
        } else if let quote = data.quote as? StellarSwapFinalQuote {
            guard let account = accountManager.activeAccount else {
                throw SendError.noActiveAccount
            }

            let keyPair = try StellarKitManager.keyPair(accountType: account.type)
            try await StellarSendHelper.send(
                transactionData: quote.transactionData,
                token: tokenIn,
                adjustNativeBalance: false,
                keyPair: keyPair
            )
        } else if let quote = data.quote as? MoneroSwapFinalQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? MoneroAdapter else {
                throw SendError.noMoneroAdapter
            }

            try adapter.send(
                to: quote.address,
                amount: quote.amount,
                priority: quote.priority,
                memo: quote.memo
            )
        }

        if !walletManager.activeWallets.contains(where: { $0.token == tokenOut }), let activeAccount = accountManager.activeAccount {
            let wallet = Wallet(token: tokenOut, account: activeAccount)
            walletManager.save(wallets: [wallet])
        }
    }
}

extension MultiSwapSendHandler {
    class SendData: ISendData {
        let tokenIn: Token
        let tokenOut: Token
        let amountIn: Decimal
        let quote: ISwapFinalQuote
        let otherSections: [SendDataSection]

        init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: ISwapFinalQuote, otherSections: [SendDataSection]) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.quote = quote
            self.otherSections = otherSections
        }

        var feeData: FeeData? {
            quote.feeData
        }

        var canSend: Bool {
            quote.canSwap
        }

        var rateCoins: [Coin] {
            [tokenIn.coin, tokenOut.coin]
        }

        var customSendButtonTitle: String? {
            nil
        }

        func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
            quote.cautions(baseToken: baseToken) + priceImpactCautions(baseToken: baseToken, currency: currency, rates: rates)
        }

        private func priceImpact(baseToken _: Token, currency _: Currency, rates: [String: Decimal]) -> Decimal? {
            let fiatAmountIn = rates[tokenIn.coin.uid].map { amountIn * $0 }
            let fiatAmountOut = rates[tokenOut.coin.uid].map { quote.amountOut * $0 }

            if let fiatAmountIn, let fiatAmountOut, fiatAmountIn != 0, fiatAmountIn > fiatAmountOut {
                let priceImpact = (fiatAmountOut * 100 / fiatAmountIn) - 100
                return priceImpact
            }

            return nil
        }

        private func priceImpactCautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let priceImpact = priceImpact(baseToken: baseToken, currency: currency, rates: rates) {
                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                switch level {
                case .warning: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_high".localized(PriceImpact.display(value: priceImpact)), type: .warning))
                case .forbidden: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(PriceImpact.display(value: priceImpact)), type: .error))
                default: ()
                }
            }

            return cautions
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            .init([
                .amount(
                    token: tokenIn,
                    appValueType: .regular(appValue: AppValue(token: tokenIn, value: amountIn)),
                    currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: amountIn * $0) },
                ),
                .amount(
                    token: tokenOut,
                    appValueType: .regular(appValue: AppValue(token: tokenOut, value: quote.amountOut)),
                    currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: quote.amountOut * $0) },
                ),
            ], isFlow: true)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields: [SendField] = []

            fields.append(
                .price(
                    title: "swap.price".localized,
                    tokenA: tokenIn,
                    tokenB: tokenOut,
                    amountA: amountIn,
                    amountB: quote.amountOut
                )
            )

            if let priceImpact = priceImpact(baseToken: baseToken, currency: currency, rates: rates) {
                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                switch level {
                case .normal, .warning, .forbidden:
                    fields.append(
                        .simpleValue(
                            title: "swap.price_impact".localized,
                            value: ComponentText(text: PriceImpact.display(value: priceImpact), colorStyle: level.valueLevel.colorStyle)
                        )
                    )
                default: ()
                }
            }

            fields.append(contentsOf: quote.fields(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                baseToken: baseToken,
                currency: currency,
                tokenInRate: rates[tokenIn.coin.uid],
                tokenOutRate: rates[tokenOut.coin.uid],
                baseTokenRate: rates[baseToken.coin.uid]
            ))

            return [
                flowSection(baseToken: baseToken, currency: currency, rates: rates),
                .init(fields, isMain: false),
            ] + otherSections
        }
    }

    enum SendError: Error {
        case invalidData
        case invalidTransactionData
        case noGasLimit
        case noGasPrice
        case noEvmKitWrapper
        case noTronKitWrapper
        case noBitcoinAdapter
        case noSendParameters
        case noZcashAdapter
        case noMoneroAdapter
        case noProposal
        case noTonAdapter
        case noActiveAccount

        case unsupportedTokenIn
        case unsupportedTokenOut
        case noCommonProvider
        case noRoutes
        case noTransactionData
        case noJettonAdapter
        case noInboundAddress
    }
}

extension MultiSwapSendHandler {
    static func instance(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider) -> MultiSwapSendHandler? {
        let baseToken: Token?

        switch tokenIn.type {
        case .native, .derived, .addressType:
            baseToken = tokenIn
        case .eip20, .spl, .jetton, .stellar:
            baseToken = try? Core.shared.marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native))
        case .unsupported:
            baseToken = nil
        }

        guard let baseToken else {
            return nil
        }

        return MultiSwapSendHandler(baseToken: baseToken, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)
    }
}
