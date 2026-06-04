import Combine
import Foundation
import MarketKit

// Decorator: broadcasts via per-chain broadcaster, then submits proof to OCP /tx.
class OpenCryptoPaySendHandler {
    private let payment: OpenCryptoPayPayment
    private let entry: OpenCryptoPayPayment.Entry
    private let innerHandler: ISendHandler
    private let broadcaster: IOpenCryptoPayBroadcaster
    private let submitter: OpenCryptoPaySubmitter
    private let paymentManager: OpenCryptoPayPaymentManager
    private let proofWorkerProvider: OpenCryptoPayProofWorkerProvider
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var expirationTimer: Timer?

    // Type A: signed-hex + expired quote = burned EOA nonce.
    private let quoteExpiryGuardSeconds: TimeInterval = 30

    init(payment: OpenCryptoPayPayment,
         entry: OpenCryptoPayPayment.Entry,
         innerHandler: ISendHandler,
         broadcaster: IOpenCryptoPayBroadcaster,
         submitter: OpenCryptoPaySubmitter,
         paymentManager: OpenCryptoPayPaymentManager,
         accountManager: AccountManager = Core.shared.accountManager,
         walletManager: WalletManager = Core.shared.walletManager,
         proofWorkerProvider: OpenCryptoPayProofWorkerProvider = Core.shared.openCryptoPay.proofWorkerProvider)
    {
        self.payment = payment
        self.entry = entry
        self.innerHandler = innerHandler
        self.broadcaster = broadcaster
        self.submitter = submitter
        self.paymentManager = paymentManager
        self.proofWorkerProvider = proofWorkerProvider
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

        let accountId = payment.capturedAccountId
        let result = try await broadcaster.broadcast(data: ocpData.inner)

        guard let hash = result.transactionHash else {
            // No txHash (Bitcoin pre-kit) — can't persist/retry. Best-effort one-shot submit.
            try? await submitter.submit(callback: payment.callback, quote: payment.quoteId, method: entry.method, proof: result.proof)
            return
        }

        do {
            // First proof attempt by the submitter itself (one-shot, inline).
            try await submitter.submit(callback: payment.callback, quote: payment.quoteId, method: entry.method, proof: result.proof)
            paymentManager.save(transactionHash: hash, accountId: accountId, payment: payment, entry: entry, submitted: true)
        } catch {
            if OpenCryptoPaySubmitError.isTerminal(error) {
                paymentManager.save(transactionHash: hash, accountId: accountId, payment: payment, entry: entry, submitted: false, proofFailed: true)
            } else {
                guard let record = paymentManager.save(transactionHash: hash, accountId: accountId, payment: payment, entry: entry, submitted: false) else {
                    throw SendError.proofPersistFailed
                }
                proofWorkerProvider.schedule(record: record)
            }
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
        case proofPersistFailed

        var errorDescription: String? {
            switch self {
            case .invalidData: return "open_crypto_pay.error.invalid_data".localized
            case .proofPersistFailed: return "open_crypto_pay.error.proof_persist_failed".localized
            }
        }
    }
}
