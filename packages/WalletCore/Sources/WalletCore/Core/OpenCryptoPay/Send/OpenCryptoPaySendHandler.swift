import Combine
import Foundation
import MarketKit
import WalletCore

// Decorator: broadcasts via per-chain broadcaster, then submits proof to OCP /tx.
class OpenCryptoPaySendHandler {
    private let payment: OpenCryptoPayPayment
    private let entry: OpenCryptoPayPayment.Entry
    private let innerHandler: ISendHandler
    private let broadcaster: OpenCryptoPayBroadcaster
    private let submitter: OpenCryptoPaySubmitter
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var expirationTimer: Timer?

    // Type A: signed-hex + expired quote = burned EOA nonce.
    private let quoteExpiryGuardSeconds: TimeInterval = 30

    init(payment: OpenCryptoPayPayment,
         entry: OpenCryptoPayPayment.Entry,
         innerHandler: ISendHandler,
         broadcaster: OpenCryptoPayBroadcaster,
         submitter: OpenCryptoPaySubmitter,
         accountManager: AccountManager = Core.shared.accountManager,
         walletManager: WalletManager = Core.shared.walletManager)
    {
        self.payment = payment
        self.entry = entry
        self.innerHandler = innerHandler
        self.broadcaster = broadcaster
        self.submitter = submitter
        self.accountManager = accountManager
        self.walletManager = walletManager

        scheduleExpirationRefresh()
    }

    deinit {
        expirationTimer?.invalidate()
    }

    private func scheduleExpirationRefresh() {
        let interval = payment.quoteExpirationDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        expirationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.refreshSubject.send()
        }
    }
}

extension OpenCryptoPaySendHandler: ISendHandler {
    var baseToken: Token { innerHandler.baseToken }
    var syncingText: String? { innerHandler.syncingText }
    var expirationDuration: Int? { innerHandler.expirationDuration }
    var initialTransactionSettings: InitialTransactionSettings? { innerHandler.initialTransactionSettings }
    var menuItems: [SendMenuItem] { innerHandler.menuItems }
    var refreshPublisher: AnyPublisher<Void, Never>? {
        let own = refreshSubject.eraseToAnyPublisher()
        guard let inner = innerHandler.refreshPublisher else { return own }
        return inner.merge(with: own).eraseToAnyPublisher()
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let inner = try await innerHandler.sendData(transactionSettings: transactionSettings)
        return OpenCryptoPaySendData(
            inner: inner,
            recipient: payment.recipient,
            expirationDate: payment.quoteExpirationDate,
            isExpired: Date() >= payment.quoteExpirationDate
        )
    }

    func send(data: ISendData) async throws {
        guard let ocpData = data as? OpenCryptoPaySendData else {
            throw SendError.invalidData
        }
        try preSendGuards()

        let proof = try await broadcaster.broadcast(data: ocpData.inner)

        do {
            try await submitter.submit(
                callback: payment.callback,
                quote: payment.quoteId,
                method: entry.method,
                proof: proof
            )
        } catch {
            // Type B: tx on chain but merchant didn't ack — surface txHash for manual recovery.
            if case let .tx(hash) = proof {
                throw SendError.submitFailedAfterBroadcast(txHash: hash, underlying: error)
            }
            throw error
        }
    }

    private func preSendGuards() throws {
        guard accountManager.activeAccount?.id == payment.capturedAccountId else {
            throw OpenCryptoPayManager.Error.accountChanged
        }
        guard walletManager.activeWallets.contains(where: { $0.token == entry.token }) else {
            throw OpenCryptoPayManager.Error.accountChanged
        }
        let safetyMargin = Date().addingTimeInterval(quoteExpiryGuardSeconds)
        guard payment.quoteExpirationDate > safetyMargin else {
            throw OpenCryptoPayManager.Error.quoteExpired
        }
    }
}

extension OpenCryptoPaySendHandler {
    enum SendError: LocalizedError {
        case invalidData
        // Broadcast OK, submit failed; txHash is on-chain.
        case submitFailedAfterBroadcast(txHash: String, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .invalidData: return "open_crypto_pay.error.invalid_data".localized
            case let .submitFailedAfterBroadcast(txHash, _):
                let prefix = String(txHash.prefix(10))
                return "open_crypto_pay.error.submit_failed_after_broadcast".localized(prefix)
            }
        }
    }
}
