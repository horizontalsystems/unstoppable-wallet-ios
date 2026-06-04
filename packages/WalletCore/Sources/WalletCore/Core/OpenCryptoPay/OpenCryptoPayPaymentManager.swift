import Combine
import Foundation
import HsToolKit
import MarketKit

class OpenCryptoPayPaymentManager {
    private let storage: OpenCryptoPayPaymentStorage
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    private let updatedSubject = PassthroughSubject<Void, Never>()
    var updatedPublisher: AnyPublisher<Void, Never> { updatedSubject.eraseToAnyPublisher() }

    init(storage: OpenCryptoPayPaymentStorage, accountManager: AccountManager, logger: Logger?) {
        self.storage = storage
        self.logger = logger

        accountManager.accountDeletedPublisher
            .sink { [weak self] account in self?.clear(accountId: account.id) }
            .store(in: &cancellables)

        let liveAccountIds = accountManager.accounts.map(\.id)
        do {
            try storage.clear(exceptAccountIds: liveAccountIds)
        } catch {
            logger?.log(level: .error, message: "OCP orphan-repair failed: \(error)")
        }
    }

    @discardableResult
    private func wrap(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            return true
        } catch {
            logger?.log(level: .error, message: "OCP write failed: \(error)")
            return false
        }
    }
}

extension OpenCryptoPayPaymentManager {
    func record(transactionHash: String, accountId: String) throws -> OpenCryptoPayPaymentRecord? {
        try storage.record(transactionHash: Self.normalized(transactionHash), accountId: accountId)
    }

    func pending() -> [OpenCryptoPayPaymentRecord] {
        do {
            let result = try storage.pending()
            return result
        } catch {
            logger?.log(level: .error, message: "OCP pending read failed: \(error)")
            return []
        }
    }

    @discardableResult
    func save(transactionHash: String, accountId: String, payment: OpenCryptoPayPayment, entry: OpenCryptoPayPayment.Entry, submitted: Bool, proofFailed: Bool = false) -> OpenCryptoPayPaymentRecord? {
        let now = Date().timeIntervalSince1970
        let record = OpenCryptoPayPaymentRecord(
            accountId: accountId,
            transactionHash: Self.normalized(transactionHash),
            paymentId: Self.sanitize(payment.id),
            quoteId: Self.sanitize(payment.quoteId),
            callback: payment.callback.absoluteString,
            method: entry.method,
            merchant: Self.sanitize(payment.recipient.name),
            createdAt: now,
            proofSubmittedAt: submitted ? now : nil,
            proofFailedAt: proofFailed ? now : nil,
            lastAttemptedAt: nil
        )
        return wrap { try storage.insert(record: record) } ? record : nil
    }

    func markSubmitted(transactionHash: String, accountId: String) {
        if wrap({ try storage.markSubmitted(transactionHash: Self.normalized(transactionHash), accountId: accountId, at: Date().timeIntervalSince1970) }) {
            updatedSubject.send()
        }
    }

    func markFailed(transactionHash: String, accountId: String) {
        if wrap({ try storage.markFailed(transactionHash: Self.normalized(transactionHash), accountId: accountId, at: Date().timeIntervalSince1970) }) {
            updatedSubject.send()
        }
    }

    func markAttempted(transactionHash: String, accountId: String, at: Double) {
        wrap { try storage.markAttempted(transactionHash: Self.normalized(transactionHash), accountId: accountId, at: at) }
    }

    func clear(accountId: String) {
        wrap { try storage.clear(accountId: accountId) }
    }
}

extension OpenCryptoPayPaymentManager {
    // strip leading 0x only; no lowercasing (base58 is case-sensitive, kit hex is already lowercase)
    static func normalized(_ hash: String) -> String {
        hash.hasPrefix("0x") ? String(hash.dropFirst(2)) : hash
    }

    static func sanitize(_ string: String) -> String {
        var forbidden = CharacterSet.controlCharacters
        forbidden.insert(charactersIn: "\u{200B}\u{200C}\u{200D}\u{FEFF}\u{2060}\u{2066}\u{2067}\u{2068}\u{2069}\u{061C}\u{202A}\u{202B}\u{202C}\u{202D}\u{202E}")
        let filtered = String(String.UnicodeScalarView(string.unicodeScalars.filter { !forbidden.contains($0) }))
        let normalized = filtered.precomposedStringWithCanonicalMapping.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(normalized.prefix(64))
    }
}
