import Combine
import Foundation
import HsExtensions
import MarketKit

public class SendViewModel: ObservableObject {
    private let autoRefreshDuration: Double = 20

    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let recentAddressStorage = Core.shared.recentAddressStorage
    private let appManager = Core.shared.appManager

    private var syncTask: AnyTask?
    private var ratesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    public let handler: ISendHandler?
    let transactionService: ITransactionService?
    public let currency: Currency

    private let address: String?

    @Published public var rates = [String: Decimal]()

    @Published public var sendData: ISendData?

    // A live send owns the screen: the quote-expiry timer is stopped so it can't swap the
    // send button for "Refresh" mid-send (for broadcast providers the window is 1-3 s, but a
    // StellarBroker session runs for minutes — a mid-session "Refresh" would allow a second
    // committed quote and a concurrent double-spending session). Any sync already in flight is
    // cancelled with it: it would otherwise land and overwrite `sendData`/`state` mid-send,
    // re-quoting under the running execution. On failure the expiry clock resumes from the
    // ORIGINAL deadline, so an already-stale quote expires immediately; success dismisses
    // the screen.
    @Published var sending = false {
        didSet {
            if sending {
                stopAutoQuoting()
                syncTask = nil
            } else if oldValue {
                autoQuoteIfRequired()
            }
        }
    }

    // Set when a send threw AFTER value may already have moved on-chain (a broker session that
    // signed and submitted, then failed mid-trade). The swap is already persisted and tracking
    // owns the outcome from here, so the screen must NOT return to a retryable state — sliding
    // again would run a second execution on top of a partially-filled one.
    @Published private(set) var partiallyExecuted = false

    @Published var transactionSettingsModified = false

    // Set when a non-auto-refreshing quote (a swap) reaches its expiration. The UI swaps the
    // send action for a "Refresh" button; cleared on every state change (a fresh sync clears it).
    @Published public var expired = false

    private var nextRefreshTime: Double?

    private let errorSubject = PassthroughSubject<String, Never>()

    @Published public var state: State = .syncing {
        didSet {
            timer?.invalidate()
            nextRefreshTime = nil
            expired = false

            if case .success = state {
                let duration = handler?.expirationDuration.map { Double($0) } ?? autoRefreshDuration
                nextRefreshTime = Date().timeIntervalSince1970 + duration

                timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                    self?.onExpiration()
                }
            }
        }
    }

    public init(sendData: SendData, address: String? = nil) {
        handler = SendHandlerFactory.handler(sendData: sendData)
        currency = currencyManager.baseCurrency
        self.address = address

        if let handler {
            transactionService = TransactionServiceFactory.transactionService(sendData: sendData, baseToken: handler.baseToken, initialTransactionSettings: handler.initialTransactionSettings)
        } else {
            transactionService = nil
        }

        transactionService?.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.syncTransactionSettingsModified()
                self?.sync()
            }
            .store(in: &cancellables)

        handler?.refreshPublisher?
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync()
            }
            .store(in: &cancellables)

        appManager.didEnterBackgroundPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.stopAutoQuoting() }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.autoQuoteIfRequired() }
            .store(in: &cancellables)

        sync()
    }

    public var cautions: [CautionNew] {
        var cautions = transactionService?.cautions ?? []

        if let sendData, let baseToken = handler?.baseToken {
            cautions.append(contentsOf: sendData.cautions(baseToken: baseToken, currency: currency, rates: rates))
        }

        return cautions
    }

    public var canSend: Bool {
        // A partially-executed send is never retryable — see `partiallyExecuted`.
        guard !partiallyExecuted else {
            return false
        }

        guard let sendData, sendData.canSend else {
            return false
        }

        if let service = transactionService, service.cautions.contains(where: { $0.type == .error }) {
            return false
        }

        return true
    }

    private func syncTransactionSettingsModified() {
        transactionSettingsModified = transactionService?.modified ?? false
    }

    @MainActor private func syncRates(coins: [Coin]) {
        let coinUids = Array(Set(coins)).map(\.uid)

        rates = marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code).mapValues { $0.value }
        ratesCancellable = marketKit.coinPriceMapPublisher(coinUids: coinUids, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rates in self?.rates = rates.mapValues { $0.value } }
    }

    @MainActor private func set(sending: Bool) {
        self.sending = sending
    }

    @MainActor private func set(partiallyExecuted: Bool) {
        self.partiallyExecuted = partiallyExecuted
    }

    @MainActor private func report(error: Error) {
        errorSubject.send(error.smartDescription)
    }
}

public extension SendViewModel {
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    internal func stopAutoQuoting() {
        timer?.invalidate()
    }

    internal func autoQuoteIfRequired() {
        guard !sending, !partiallyExecuted, !state.isSyncing, let nextRefreshTime else {
            return
        }

        let now = Date().timeIntervalSince1970

        if now > nextRefreshTime {
            onExpiration()
        } else {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: nextRefreshTime - now, repeats: false) { [weak self] _ in
                self?.onExpiration()
            }
        }
    }

    // Reached when the current quote hits its expiration. Regular sends silently re-quote (fee
    // refresh); handlers that opt out of auto-refresh (swaps) mark the quote expired instead and
    // wait for the user to tap "Refresh".
    internal func onExpiration() {
        // Never expire under a live send — an already-armed timer can still fire after
        // `sending` flipped true (the didSet only stops FUTURE firings).
        guard !sending else {
            return
        }

        if handler?.autoRefreshEnabled ?? true {
            sync(silent: true)
        } else {
            expired = true
        }
    }

    func sync(silent: Bool = false) {
        guard let handler else {
            return
        }

        syncTask = nil

        if !state.isSyncing, !silent {
            state = .syncing
        }

        syncTask = Task { [weak self, handler, transactionService] in
            var sendData: ISendData?
            var state: State

            do {
                try await transactionService?.sync()

                let _sendData = try await handler.sendData(transactionSettings: transactionService?.transactionSettings)

                await self?.syncRates(coins: [handler.baseToken.coin] + _sendData.rateCoins)

                sendData = _sendData
                state = .success
            } catch {
                state = .failed(error: error)
            }

            if !Task.isCancelled {
                await MainActor.run { [weak self, sendData, state] in
                    self?.sendData = sendData
                    self?.state = state
                }
            }
        }
        .erased()
    }

    func send() async throws {
        do {
            guard let handler else {
                throw SendError.noHandler
            }

            guard let sendData else {
                throw SendError.noSendData
            }

            await set(sending: true)

            _ = try await handler.send(data: sendData)

            if let address {
                try? recentAddressStorage.save(address: address, blockchainUid: handler.baseToken.blockchain.uid)
            }
        } catch {
            // Order matters: mark the partial BEFORE clearing `sending`, whose didSet resumes
            // auto-quoting — the flag is what stops it (and the send button) coming back.
            if let partial = error as? IPartialExecutionError, partial.partialTxHash != nil {
                await set(partiallyExecuted: true)
            }

            await set(sending: false)
            await report(error: error)
            throw error
        }
    }
}

extension SendViewModel {
    public enum State {
        case syncing
        case success
        case failed(error: Error)

        public var isSyncing: Bool {
            switch self {
            case .syncing: return true
            default: return false
            }
        }

        public var isSuccess: Bool {
            switch self {
            case .success: return true
            default: return false
            }
        }
    }

    enum SendError: Error {
        case noHandler
        case noSendData
    }
}
