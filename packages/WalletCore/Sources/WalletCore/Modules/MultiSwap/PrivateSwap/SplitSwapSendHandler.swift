import Combine
import Foundation
import MarketKit

class SplitSwapSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .splitSwap(tokenIn, tokenOut, amountIn, provider, recipients) = sendData else { return nil }

        guard let baseToken = MultiSwapSendHandler.baseToken(tokenIn: tokenIn) else {
            return nil
        }

        return SplitSwapSendHandler(baseToken: baseToken, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, recipients: recipients)
    }

    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let restoreSettingsManager = Core.shared.restoreSettingsManager
    private let swapHistoryManager = Core.shared.swapHistoryManager

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: ISplitSwapProvider
    let recipients: [SplitRecipient]

    // resolved once per confirmation: the mechanism is fixed by (chain, account)
    private lazy var broadcaster: ISwapBroadcaster? = accountManager.activeAccount.flatMap {
        try? SwapBroadcasterFactory.broadcaster(blockchainType: tokenIn.blockchainType, account: $0)
    }

    private let refreshSubject = PassthroughSubject<Void, Never>()

    init(baseToken: Token, tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: ISplitSwapProvider, recipients: [SplitRecipient]) {
        self.baseToken = baseToken
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider
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

    // As the standard swap: the confirmation quote is a side-effect-free preview, silently re-requested on
    // expiry; the order is created by `provider.splitCommit(finalQuote:)` when the user slides.
    var autoRefreshEnabled: Bool {
        true
    }

    // The recipients and the split are chosen before confirmation: only the generic fee settings remain
    var menuItems: [SendMenuItem] {
        []
    }

    var refreshPublisher: AnyPublisher<Void, Never>? {
        refreshSubject.eraseToAnyPublisher()
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        guard let account = accountManager.activeAccount else {
            throw MultiSwapSendHandler.SendError.noActiveAccount
        }

        guard !account.watchAccount else {
            throw SwapBroadcasterError.noBroadcaster
        }

        let preview = try await provider.splitPreview(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            recipients: recipients,
            slippage: MultiSwapSlippage.default,
            transactionSettings: transactionSettings
        )
        preview.quote.preciseEstimateTime = provider.preciseEstimateTime

        guard let broadcaster else {
            throw SwapBroadcasterError.noBroadcaster
        }

        // the executable is built at send time, from the quote commit rebuilds against the real deposit
        return SendData(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            quote: preview.quote,
            broadcaster: broadcaster,
            outputAmounts: preview.outputAmounts,
            recipients: recipients
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw MultiSwapSendHandler.SendError.invalidData
        }

        // Creates the order. On failure the token is never reused: the reason is toasted and a fresh
        // preview is requested.
        let commitment: SplitSwapCommitment
        do {
            commitment = try await provider.splitCommit(finalQuote: data.quote)
        } catch {
            let message = MultiSwapSendHandler.commitFailureMessage(error)
            await MainActor.run { HudHelper.instance.show(banner: .error(string: message)) }
            refreshSubject.send()
            throw MultiSwapSendHandler.CommitFailedError(underlying: error)
        }

        let result: BroadcastResult
        do {
            let executable = commitment.quote.executable(tokenIn: tokenIn)
            let prepared = try await data.broadcaster.prepare(executable)
            result = try await data.broadcaster.submit(prepared)
        } catch {
            // The order exists and the preview is consumed: re-preview so a retry never reuses it
            refreshSubject.send()
            throw error
        }

        saveSwap(commitment: commitment, txHash: result.txHash, trackingHandle: result.trackingHandle)

        // Best-effort and off the critical path: funds have moved, so the screen must not wait on the report.
        // The answer (the aggregate `{ splitUuid, status, hash }`) is ignored; tracking reads the status.
        if let txHash = result.txHash {
            Task { [provider] in
                do {
                    try await provider.reportSplitInboundTxHash(splitUuid: commitment.splitUuid, txHash: txHash)
                } catch {
                    Core.instance?.logError(message: "split swap signed report failed: \(error)", save: false)
                }
            }
        }

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

    // One record for the whole split, tracked by its `splitUuid`. The record names no single recipient;
    // `outputs` is seeded with every recipient and its deposit share, so the info screen lists them
    // before the first track, and tracking merges its per-output state into these entries by index.
    private func saveSwap(commitment: SplitSwapCommitment, txHash: String?, trackingHandle: String?) {
        guard let account = accountManager.activeAccount else {
            return
        }

        let quote = commitment.quote
        let outputs = recipients.enumerated().map { index, recipient in
            Swap.Output(
                index: index,
                status: .notStarted,
                toAddress: recipient.address,
                fromAmount: amountIn * Decimal(recipient.percent) / 100,
                toAmount: nil,
                legs: []
            )
        }
        let swap = Swap(
            uid: UUID().uuidString,
            txHash: txHash,
            trackingHandle: trackingHandle,
            accountId: account.id,
            providerId: provider.id,
            status: .pending,
            operation: .splitSwap,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: quote.amountOut,
            recipient: nil,
            toAddress: recipients.first?.address ?? "",
            depositAddress: quote.depositAddress,
            providerSwapId: commitment.splitUuid,
            sourceAddress: nil,
            refundAddress: quote.refundAddress,
            estimatedTime: quote.estimatedTime,
            date: Date(),
            outputs: outputs
        )

        swapHistoryManager.save(swap: swap)
    }
}

extension SplitSwapSendHandler {
    final class SendData: MultiSwapSendHandler.SendData {
        let outputAmounts: [Decimal]
        let recipients: [SplitRecipient]

        init(
            tokenIn: Token,
            tokenOut: Token,
            amountIn: Decimal,
            quote: SwapFinalQuote,
            broadcaster: ISwapBroadcaster,
            outputAmounts: [Decimal],
            recipients: [SplitRecipient]
        ) {
            self.outputAmounts = outputAmounts
            self.recipients = recipients

            super.init(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote, broadcaster: broadcaster, otherSections: [])
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
                let amountOut = outputAmounts.indices.contains(index) ? outputAmounts[index] : quote.amountOut * Decimal(recipient.percent) / 100

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
