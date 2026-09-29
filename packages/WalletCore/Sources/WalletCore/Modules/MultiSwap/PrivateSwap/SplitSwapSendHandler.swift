import Combine
import Foundation
import MarketKit

class SplitSwapSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .splitSwap(tokenIn, tokenOut, amountIn, provider, quote, recipients) = sendData else { return nil }

        guard let baseToken = MultiSwapSendHandler.baseToken(tokenIn: tokenIn) else {
            return nil
        }

        return SplitSwapSendHandler(baseToken: baseToken, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, quote: quote, recipients: recipients)
    }

    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let restoreSettingsManager = Core.shared.restoreSettingsManager

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: ISplitSwapProvider
    let quote: SplitMultiSwapQuote
    let recipients: [SplitRecipient]

    // resolved once per confirmation: the mechanism is fixed by (chain, account)
    private lazy var broadcaster: ISwapBroadcaster? = accountManager.activeAccount.flatMap {
        try? SwapBroadcasterFactory.broadcaster(blockchainType: tokenIn.blockchainType, account: $0)
    }

    init(baseToken: Token, tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: ISplitSwapProvider, quote: SplitMultiSwapQuote, recipients: [SplitRecipient]) {
        self.baseToken = baseToken
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider
        self.quote = quote
        self.recipients = recipients
    }
}

extension SplitSwapSendHandler: ISendHandler {
    var syncingText: String? {
        "swap.confirmation.quoting".localized
    }

    var expirationDuration: Int? {
        broadcaster?.expirationDuration ?? 15
    }

    // Same as the standard swap: the confirmation holds a committed order, refreshed on demand only
    var autoRefreshEnabled: Bool {
        false
    }

    // The recipients and the split are chosen before confirmation: only the generic fee settings remain
    var menuItems: [SendMenuItem] {
        []
    }

    var refreshPublisher: AnyPublisher<Void, Never>? {
        nil
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        // the confirmation quote commits an order with the provider, so the account is checked before it, not after
        guard let account = accountManager.activeAccount else {
            throw MultiSwapSendHandler.SendError.noActiveAccount
        }

        guard !account.watchAccount else {
            throw SwapBroadcasterError.noBroadcaster
        }

        let finalQuote = try await provider.splitConfirmationQuote(
            quote: quote,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            recipients: recipients,
            transactionSettings: transactionSettings
        )
        finalQuote.preciseEstimateTime = provider.preciseEstimateTime

        guard let broadcaster else {
            throw SwapBroadcasterError.noBroadcaster
        }

        let prepared = try await broadcaster.prepare(finalQuote.executable(tokenIn: tokenIn))

        return SendData(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            quote: finalQuote,
            prepared: prepared,
            broadcaster: broadcaster,
            splitQuote: quote,
            recipients: recipients
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw MultiSwapSendHandler.SendError.invalidData
        }

        // TODO: save split swap to history (also on partial execution, as MultiSwapSendHandler does)
        _ = try await data.broadcaster.submit(data.prepared)

        // externally-delivered swaps must not auto-enable a wallet the account can't hold
        if !walletManager.activeWallets.contains(where: { $0.token == tokenOut }),
           let activeAccount = accountManager.activeAccount,
           activeAccount.type.supports(token: tokenOut)
        {
            restoreSettingsManager.saveDefaultSettingsIfNeeded(account: activeAccount, blockchainType: tokenOut.blockchainType)

            let wallet = Wallet(token: tokenOut, account: activeAccount)
            walletManager.save(wallets: [wallet])
        }
    }
}

extension SplitSwapSendHandler {
    final class SendData: MultiSwapSendHandler.SendData {
        let splitQuote: SplitMultiSwapQuote
        let recipients: [SplitRecipient]

        init(
            tokenIn: Token,
            tokenOut: Token,
            amountIn: Decimal,
            quote: SwapFinalQuote,
            prepared: IPrepared,
            broadcaster: ISwapBroadcaster,
            splitQuote: SplitMultiSwapQuote,
            recipients: [SplitRecipient]
        ) {
            self.splitQuote = splitQuote
            self.recipients = recipients

            super.init(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote, prepared: prepared, broadcaster: broadcaster, otherSections: [])
        }

        // Input, then an output + address pair per recipient. The arrow sits only under the input;
        // the recipient pairs are separated by a plain line.
        override func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            var fields: [SendField] = [
                .amount(
                    token: tokenIn,
                    appValueType: .regular(appValue: AppValue(token: tokenIn, value: amountIn)),
                    currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: amountIn * $0) }
                ),
            ]
            var dividers: [SendDataSection.FlowDivider] = [.arrow]

            for (index, recipient) in recipients.enumerated() {
                let amountOut = splitQuote.outputAmounts.indices.contains(index) ? splitQuote.outputAmounts[index] : quote.amountOut * Decimal(recipient.percent) / 100

                if index > 0 {
                    dividers.append(.line)
                }

                fields.append(
                    .splitOutput(
                        token: tokenOut,
                        percent: recipient.percent,
                        appValueType: .regular(appValue: AppValue(token: tokenOut, value: amountOut)),
                        currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: amountOut * $0) }
                    )
                )
                dividers.append(.hidden)

                fields.append(
                    .recipient(
                        title: "swap.private.address".localized(index + 1),
                        value: recipient.address,
                        copyable: true,
                        blockchainType: tokenOut.blockchainType
                    )
                )
            }

            return .init(fields, isFlow: true, flowDividers: dividers)
        }
    }
}
