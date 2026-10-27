import Combine
import Foundation
import MarketKit

// The Private (split) swap tab: the same input handling as the Standard tab, with its own tokens and
// amount, quoted across the split-capable providers only. The received amount is delivered to two
// addresses, split by `splitPercent`.
final class SplitSwapViewModel: MultiSwapViewModel {
    static let percentRange = 10 ... 90
    static let percentStep = 10
    static let defaultPercent = 50

    // Share of the output delivered to Address 1; Address 2 gets the rest
    @Published private(set) var splitPercent = SplitSwapViewModel.defaultPercent
    @Published private(set) var recipients: [ResolvedAddress?] = [nil, nil] {
        didSet { syncContactNames() }
    }

    // Contact book name of each recipient address, if any
    @Published private(set) var contactNames: [String?] = [nil, nil]

    // Output amounts of the last quote, kept while a split change requotes so the cards don't blank out
    @Published private(set) var lastOutputAmounts: [Decimal]?

    // Set at once on a split change, before the debounced requote starts, so the button switches immediately
    @Published private(set) var pendingSplitRequote = false

    // At least one split-capable provider is registered; drives the tab header's visibility. A stored
    // default, so it is in place before `super.init`, which already calls `resolveProviders()`
    @Published private(set) var splitAvailable = false

    // A split change whose debounced requote has not started yet: quotes arriving meanwhile belong to
    // an older round and must not clear `pendingSplitRequote`
    private var splitRequoteScheduled = false

    private let contactManager = Core.shared.contactManager
    private let splitSubject = PassthroughSubject<Void, Never>()
    private var splitCancellables = Set<AnyCancellable>()

    override init(token: Token? = nil, tokenOut: Token? = nil, autoResolveTokenOut: Bool = true, customDecimals: Int? = nil) {
        super.init(token: token, tokenOut: tokenOut, autoResolveTokenOut: autoResolveTokenOut, customDecimals: customDecimals)

        splitSubject
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.runSplitRequote()
            }
            .store(in: &splitCancellables)

        // Recipient addresses are chain-specific: an address entered for the previous tokenOut is
        // meaningless for the new one
        $tokenOut
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.recipients = [nil, nil]
            }
            .store(in: &splitCancellables)
    }

    override func resolveProviders() -> [IMultiSwapProvider] {
        let resolved = SwapProviderFactory.swappableProviders(ids: swapProviderManager.splitProviders).filter { $0 is ISplitSwapProvider }
        splitAvailable = !resolved.isEmpty
        return resolved
    }

    override func quoteFetcher() -> QuoteFetcher {
        let percents = percents

        return { provider, tokenIn, tokenOut, amountIn in
            guard let provider = provider as? ISplitSwapProvider else {
                throw SplitSwapError.notSupported
            }

            return try await provider.splitQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, percents: percents)
        }
    }

    override var suggestedPathEnabled: Bool {
        false
    }

    // Clears the pending flag only once the requote round has delivered its quotes; `quoting` is reset
    // before `quotes` is assigned on completion, so a round still in flight keeps the flag set
    override func didUpdateQuotes() {
        super.didUpdateQuotes()

        if pendingSplitRequote, !splitRequoteScheduled, !quoting {
            pendingSplitRequote = false
        }
    }

    override func reset() {
        super.reset()

        splitPercent = Self.defaultPercent
        recipients = [nil, nil]
        lastOutputAmounts = nil
        splitRequoteScheduled = false
        pendingSplitRequote = false
    }

    private func syncContactNames() {
        contactNames = recipients.map { recipient in
            guard let recipient, let tokenOut else {
                return nil
            }

            return contactManager.name(blockchainType: tokenOut.blockchainType, address: recipient.address)
        }
    }

    private func runSplitRequote() {
        syncQuotes()
        splitRequoteScheduled = false

        // No round started (no amount, no valid providers, or auto quoting stopped the round at once)
        if !quoting, pendingSplitRequote {
            pendingSplitRequote = false
        }
    }
}

extension SplitSwapViewModel {
    var percents: [Int] {
        [splitPercent, 100 - splitPercent]
    }

    var splitQuote: SplitMultiSwapQuote? {
        currentQuote?.quote as? SplitMultiSwapQuote
    }

    // A recipient whose address an earlier recipient already uses
    func isDuplicateRecipient(at index: Int) -> Bool {
        guard recipients.indices.contains(index), let key = recipientKey(at: index) else {
            return false
        }

        return (0 ..< index).contains { recipientKey(at: $0) == key }
    }

    var hasDuplicateRecipients: Bool {
        recipients.indices.contains { isDuplicateRecipient(at: $0) }
    }

    // EVM addresses are case-insensitive (checksum casing); other chains compare exactly
    private func recipientKey(at index: Int) -> String? {
        guard let address = recipients[index]?.address else {
            return nil
        }

        return tokenOut?.blockchainType.isEvm == true ? address.lowercased() : address
    }

    var requoting: Bool {
        quoting || pendingSplitRequote
    }

    // The amount delivered to the recipient at `index`, or the last known one while requoting
    func outputAmount(at index: Int) -> Decimal? {
        if let splitQuote, splitQuote.percents == percents, splitQuote.outputAmounts.indices.contains(index) {
            return splitQuote.outputAmounts[index]
        }

        if requoting, let lastOutputAmounts, lastOutputAmounts.indices.contains(index) {
            return lastOutputAmounts[index]
        }

        return nil
    }

    // The last round for the current split ratio returned no quote: the ratio was quoted fine before
    // (that is how the recipients screen is reached), so the provider refuses this split
    var splitUnavailable: Bool {
        !requoting && currentQuote == nil && (amountIn ?? 0) > 0 && !validProviders.isEmpty
    }

    var recipientsButtonState: PreSendButtonState {
        if requoting {
            return .init(title: "swap.quoting".localized, disabled: true, showProgress: true)
        }

        if splitUnavailable {
            return .init(title: "send.next_button".localized, disabled: true, showProgress: false)
        }

        if recipients.contains(where: { $0 == nil }) {
            return .init(title: "swap.private.enter_addresses".localized, disabled: true, showProgress: false)
        }

        if currentQuote == nil {
            return .init(title: "swap.no_quotes".localized, disabled: true, showProgress: false)
        }

        return .init(title: "send.next_button".localized, disabled: false, showProgress: false)
    }

    var splitSendData: SendData? {
        guard let tokenIn, let tokenOut, let amountIn, let currentQuote,
              let provider = currentQuote.provider as? ISplitSwapProvider,
              let quote = currentQuote.quote as? SplitMultiSwapQuote
        else {
            return nil
        }

        let addresses = recipients.compactMap { $0?.address }

        guard addresses.count == quote.percents.count else {
            return nil
        }

        let splitRecipients = zip(addresses, quote.percents).map { SplitRecipient(address: $0, percent: $1) }

        return .splitSwap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, recipients: splitRecipients)
    }

    func set(splitPercent: Int) {
        let range = Self.percentRange
        let step = Self.percentStep
        let snapped = Int((Double(splitPercent) / Double(step)).rounded()) * step
        let percent = min(max(snapped, range.lowerBound), range.upperBound)

        guard percent != self.splitPercent else {
            return
        }

        // A settled state hands its amounts to the requote: a valid split its quote's, an invalid one
        // none (n/a while loading). A change during a requote keeps what the requote already shows.
        if !requoting {
            lastOutputAmounts = splitQuote?.outputAmounts
        }

        self.splitPercent = percent
        splitRequoteScheduled = true
        pendingSplitRequote = true
        splitSubject.send()
    }

    func set(recipient: ResolvedAddress, index: Int) {
        guard recipients.indices.contains(index) else {
            return
        }

        recipients[index] = recipient
    }
}
