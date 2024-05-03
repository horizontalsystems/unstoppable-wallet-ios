import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapSendHandler {
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let accountManager = App.shared.accountManager
    private let walletManager = App.shared.walletManager

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: IMultiSwapProvider

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

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let quote = try await provider.confirmationQuote(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            transactionSettings: transactionSettings
        )

        return SendData(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote)
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try await provider.swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: data.quote)

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
        let quote: IMultiSwapConfirmationQuote

        init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: IMultiSwapConfirmationQuote) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.quote = quote
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

        func cautions(baseToken: Token) -> [CautionNew] {
            quote.cautions(baseToken: baseToken)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            var sections: [[SendField]] = [
                [
                    .amount(
                        title: "swap.you_pay".localized,
                        token: tokenIn,
                        coinValueType: .regular(coinValue: CoinValue(kind: .token(token: tokenIn), value: amountIn)),
                        currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: amountIn * $0) },
                        type: .neutral
                    ),
                    .amount(
                        title: "swap.you_get".localized,
                        token: tokenOut,
                        coinValueType: .regular(coinValue: CoinValue(kind: .token(token: tokenOut), value: quote.amountOut)),
                        currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: quote.amountOut * $0) },
                        type: .incoming
                    ),
                ],
            ]

            var priceSection: [SendField] = [
                .price(
                    title: "swap.price".localized,
                    tokenA: tokenIn,
                    tokenB: tokenOut,
                    amountA: amountIn,
                    amountB: quote.amountOut
                ),
            ]

            let priceSectionFields = quote.priceSectionFields(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                baseToken: baseToken,
                currency: currency,
                tokenInRate: rates[tokenIn.coin.uid],
                tokenOutRate: rates[tokenOut.coin.uid],
                baseTokenRate: rates[baseToken.coin.uid]
            )

            if !priceSectionFields.isEmpty {
                priceSection.append(contentsOf: priceSectionFields)
            }

            sections.append(priceSection)

            sections.append(contentsOf: quote.otherSections(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                baseToken: baseToken,
                currency: currency,
                tokenInRate: rates[tokenIn.coin.uid],
                tokenOutRate: rates[tokenOut.coin.uid],
                baseTokenRate: rates[baseToken.coin.uid]
            ))

            return sections
        }
    }

    enum SendError: Error {
        case invalidData
    }
}

extension MultiSwapSendHandler {
    static func instance(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider) -> MultiSwapSendHandler? {
        let baseToken: Token?

        switch tokenIn.type {
        case .native, .derived, .addressType:
            baseToken = tokenIn
        case .eip20, .bep2, .spl:
            baseToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native))
        case .unsupported:
            baseToken = nil
        }

        guard let baseToken else {
            return nil
        }

        return MultiSwapSendHandler(baseToken: baseToken, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)
    }
}
