import Foundation
import HsToolKit
import RxSwift
import ZcashLightClientKit

class ZcashSendService {
    // Custom fee (zip317 marginal fee) and tx expiry are kept wired end-to-end but the SDK has no
    // public parameter for them yet; the flag gates the fee-settings UI until upstream support lands.
    static let customFeeEnabled = true

    // RESEARCH SHIM: upstream has no ZcashSDK.defaultZip317MarginalFee (HS delta, replayed in step 3).
    static let defaultZip317MarginalFee = Zatoshi(5000) // ZCASH_MARGINAL_FEE
    static let zip317MarginalFeeRange = (defaultZip317MarginalFee.amount) ... (defaultZip317MarginalFee.amount * 6)

    static let defaultTxExpiryHeightDelta: UInt32 = 10

    // zcashd RPC_VERIFY_ERROR: the node has terminally rejected the tx (e.g. duplicate
    // nullifier / spent inputs); resubmitting the same bytes can never succeed.
    static let terminalNodeRejectionCode = -25

    private let synchronizer: Synchronizer
    private let migrator: ZcashMigrator
    private let terminalStore: ZcashTerminalResubmissionStore
    private let logger: HsToolKit.Logger?

    weak var syncService: ZcashSyncService?
    weak var endpointService: ZcashEndpointService?
    weak var historyService: ZcashHistoryService?

    init(synchronizer: Synchronizer, migrator: ZcashMigrator, terminalStore: ZcashTerminalResubmissionStore, logger: HsToolKit.Logger?) {
        self.synchronizer = synchronizer
        self.migrator = migrator
        self.terminalStore = terminalStore
        self.logger = logger
    }

    func sendProposal(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) async throws -> Proposal {
        guard let accountId = syncService?.accountId else {
            throw AppError.ZcashError.noAccountId
        }

        let amountInZatoshi = Zatoshi.from(decimal: amount)

        do {
            return try await synchronizer.proposeTransfer(
                accountUUID: accountId,
                recipient: address,
                amount: amountInZatoshi,
                memo: memo
            )
        } catch {
            throw ZcashSendHelper.converted(error)
        }
    }

    func sendProposal(
        outputs: [ZcashAdapter.TransferOutput],
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) async throws -> Proposal {
        guard let accountId = syncService?.accountId else {
            throw AppError.ZcashError.noAccountId
        }

        let paymentURI = createPaymentURI(outputs: outputs)

        do {
            return try await synchronizer.proposefulfillingPaymentURI(
                paymentURI,
                accountUUID: accountId
            )
        } catch {
            throw ZcashSendHelper.converted(error)
        }
    }

    private func createPaymentURI(outputs: [ZcashAdapter.TransferOutput]) -> String {
        var components = URLComponents()
        components.scheme = "zcash"
        components.path = ""

        var queryItems: [URLQueryItem] = []

        for (index, output) in outputs.enumerated() {
            if index == 0 {
                queryItems.append(URLQueryItem(name: "address", value: output.address.stringEncoded))
                queryItems.append(URLQueryItem(name: "amount", value: output.amount.description))

                if let memo = output.memo, let string = memo.toString() {
                    let base64url = encodeBase64URL(string)
                    queryItems.append(URLQueryItem(name: "memo", value: base64url))
                }
            } else {
                queryItems.append(URLQueryItem(name: "address.\(index)", value: output.address.stringEncoded))
                queryItems.append(URLQueryItem(name: "amount.\(index)", value: output.amount.description))

                if let memo = output.memo, let string = memo.toString() {
                    let base64url = encodeBase64URL(string)
                    queryItems.append(URLQueryItem(name: "memo.\(index)", value: base64url))
                }
            }
        }

        components.queryItems = queryItems
        return components.string ?? ""
    }

    private func encodeBase64URL(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func shieldProposal(
        threshold: Decimal,
        address: Recipient?,
        memo: Memo?,
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) async throws -> Proposal? {
        guard let accountId = syncService?.accountId else {
            throw AppError.ZcashError.noAccountId
        }

        let requiredMemo = try memo ?? Memo(string: "")

        var transparentAddress: TransparentAddress?
        switch address {
        case let .transparent(tAddress): transparentAddress = tAddress
        default: ()
        }

        let amountInZatoshi = Zatoshi.from(decimal: threshold)

        return try await synchronizer.proposeShielding(
            accountUUID: accountId,
            shieldingThreshold: amountInZatoshi,
            memo: requiredMemo,
            transparentReceiver: transparentAddress
        )
    }

    func sendSingle(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) -> Single<Void> {
        guard let accountId = syncService?.accountId else {
            return .error(AppError.ZcashError.noAccountId)
        }

        return Single.create { [weak self] observer in
            Task { [weak self] in
                do {
                    guard let proposal = try await self?.synchronizer.proposeTransfer(
                        accountUUID: accountId,
                        recipient: address,
                        amount: Zatoshi.from(decimal: amount),
                        memo: memo /* , zip317MarginalFee: zip317MarginalFee */
                    ) else {
                        observer(.error(AppError.unknownError))
                        return
                    }

                    try await self?.send(proposal: proposal /* , zip317MarginalFee: zip317MarginalFee */ )
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func send(
        amount: Decimal,
        address: Recipient,
        memo: Memo?,
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) async throws {
        let proposal = try await sendProposal(amount: amount, address: address, memo: memo /* , zip317MarginalFee: zip317MarginalFee */ )
        try await send(proposal: proposal /* , zip317MarginalFee: zip317MarginalFee */ )
    }

    @discardableResult func send(
        proposal: Proposal,
        zip317MarginalFee _: Zatoshi = ZcashSendService.defaultZip317MarginalFee
    ) async throws -> String? {
        guard let spendingKey = syncService?.spendingKey else {
            throw AppError.ZcashError.noReceiveAddress
        }

        return try await Core.shared.backgroundTaskManager.performCritical(name: "zcash-send") {
            try await self.send(proposal: proposal, spendingKey: spendingKey)
        }
    }

    func migrationProposal() async throws -> (amount: Decimal, fee: Decimal) {
        try await migrator.migrationProposal()
    }

    // send-max sweep to the wallet's own UA. It is an ordinary send: no stop-sync, no privacy buffer.
    // Runs under the same "zcash-send" critical section as every send, so background survivability and
    // same-bytes resubmit apply for free.
    func performMigration() async throws -> String? {
        let txId = try await Core.shared.backgroundTaskManager.performCritical(name: "zcash-send") {
            try await self.migrator.performMigration()
        }
        historyService?.reSyncPending()
        return txId
    }

    private func send(proposal: Proposal, spendingKey: UnifiedSpendingKey) async throws -> String? {
        // proving runs outside the guard; only the broadcast phase must not overlap an engine restart
        let created = try await synchronizer.broadcaster.createProposedTransactions(proposal: proposal, spendingKey: spendingKey)
        guard let endpoint = endpointService?.currentEndpoint else {
            throw AppError.ZcashError.noAccountId
        }

        let outcomes: [(txId: Data, outcome: TransactionSubmissionOutcome)]
        do {
            outcomes = try await ZcashOperationGuard.shared.withSubmission(timeout: 30) {
                await Self.submit(created: created, via: synchronizer.broadcaster, endpoint: endpoint)
            }
        } catch is ZcashOperationGuard.Failure {
            return await handOverToBackgroundResubmission(created, endpoint: endpoint, reason: "guard busy")
        }

        let mapped = Self.submitOutcomes(outcomes)
        for (txId, outcome) in outcomes {
            logger?.log(level: .debug, message: "-> TX \(txId.toHexStringTxId()): \(outcome)")
        }
        logger?.log(level: .debug, message: mapped.successCount == created.count ? "Successful sended All TXs" : "Partial/failed submit: \(mapped.successCount)/\(created.count), resubmitable: \(mapped.resubmitable)")

        historyService?.reSyncPending()

        if let submitFailure = mapped.submitFailure {
            throw submitFailure
        }

        return mapped.txIds.first
    }

    // created but never handed to a server: the SDK background resubmission owns them from here
    private func handOverToBackgroundResubmission(_ created: [CreatedTransaction], endpoint: LightWalletEndpoint, reason: String) async -> String? {
        logger?.log(level: .error, message: "Submit skipped (\(reason)), released \(created.count) tx to SDK resubmission")
        await synchronizer.broadcaster.releaseForResubmission(transactions: created, to: [endpoint])
        historyService?.reSyncPending()
        return created.first?.txId.toHexStringTxId()
    }

    static func submitOutcomes(_ outcomes: [(txId: Data, outcome: TransactionSubmissionOutcome)]) -> (successCount: Int, txIds: [String], submitFailure: Error?, resubmitable: Bool) {
        var successCount = 0
        var submitFailure: Error?
        var resubmitable = false

        for (_, outcome) in outcomes {
            switch outcome {
            case .accepted:
                successCount += 1
            case let .rejected(code, description):
                submitFailure = submitFailure ?? AppError.invalidResponse(reason: "Zcash node rejected transaction (code \(code)): \(description)")
            case .unreachable, .timedOut, .notAttempted, .cancelled:
                resubmitable = true
            }
        }

        return (successCount, outcomes.map { $0.txId.toHexStringTxId() }, submitFailure, resubmitable)
    }

    static func submit(created: [CreatedTransaction], via broadcaster: Broadcaster, endpoint: LightWalletEndpoint) async -> [(txId: Data, outcome: TransactionSubmissionOutcome)] {
        var result: [(txId: Data, outcome: TransactionSubmissionOutcome)] = []
        for transaction in created {
            // every created tx gets its own submit plan (.ready) — no early exit after a rejection
            let outcome = await broadcaster.submit(transaction: transaction, to: [endpoint])
            result.append((transaction.txId, outcome))
        }
        return result
    }

    // Directly re-broadcasts created-but-undelivered transactions with their original bytes.
    // Runs on foreground start (deferred until the first sync state with a non-zero height):
    // the SDK sync-loop resubmission only runs once the sync state machine reaches it, so a
    // short "check the app" session would never deliver without this.
    // Same-bytes resubmit is safe: an already-delivered transaction comes back as .rejected.
    func resubmitPendingTransactions() async {
        guard let endpointService else {
            return
        }

        do {
            try await ZcashOperationGuard.shared.withSubmission(timeout: 30) {
                await resubmitPendingTransactions(endpointService: endpointService)
            }
        } catch {
            // a node switch or rebuild is holding the guard — retried on next foreground anyway
            logger?.log(level: .debug, message: "Resubmit skipped: \(error)")
        }
    }

    private func resubmitPendingTransactions(endpointService: ZcashEndpointService) async {
        // snapshot once: a node switch mid-loop must not split the batch between endpoints
        let endpoint = endpointService.currentEndpoint

        let latestHeight = synchronizer.latestState.latestBlockHeight
        let overviews = await synchronizer.transactions

        let pendingTransactions = overviews.filter { $0.minedHeight == nil }
        logger?.log(
            level: .debug,
            message: "Resubmit scan: endpoint=\(endpoint.host):\(endpoint.port) secure=\(endpoint.secure) latestHeight=\(latestHeight) pending=\(pendingTransactions.count)"
        )

        terminalStore.prune(
            activeUnminedTxIds: Set(pendingTransactions.map { $0.rawID.toHexStringTxId() }),
            latestHeight: latestHeight
        )

        for overview in pendingTransactions {
            let hasRaw = overview.raw != nil
            let expiryHeight = overview.expiryHeight?.description ?? "nil"
            let isCandidate = Self.isResubmissionCandidate(
                isSentTransaction: overview.isSentTransaction,
                minedHeight: overview.minedHeight,
                hasRaw: hasRaw,
                expiryHeight: overview.expiryHeight,
                latestHeight: latestHeight
            )
            logger?.log(
                level: .debug,
                message: "Resubmit eligibility: tx=\(overview.rawID.toHexStringTxId()) sent=\(overview.isSentTransaction) raw=\(hasRaw) expiry=\(expiryHeight) latestHeight=\(latestHeight) eligible=\(isCandidate)"
            )

            guard isCandidate else {
                continue
            }
            let txId = overview.rawID.toHexStringTxId()
            guard !terminalStore.isMarked(txId: txId) else {
                logger?.log(level: .debug, message: "Resubmit suppressed (terminal node rejection): \(txId)")
                continue
            }
            guard let raw = overview.raw else {
                logger?.log(level: .error, message: "Resubmit skip \(txId): missing raw bytes")
                continue
            }

            let created = CreatedTransaction(txId: overview.rawID, raw: raw, expiryHeight: overview.expiryHeight)
            let outcome = await synchronizer.broadcaster.submit(transaction: created, to: [endpoint])

            if Self.isTerminalRejection(outcome) {
                // marker first, then redacted diagnostics: no raw tx / node message is persisted
                terminalStore.markNodeRejected(txId: txId, expiryHeight: overview.expiryHeight ?? 0)
                logger?.log(level: .error, message: "Resubmit terminal node rejection (code \(Self.terminalNodeRejectionCode)): \(txId)")
            } else if case .accepted = outcome {
                logger?.log(level: .debug, message: "Resubmit accepted: \(txId)")
            } else {
                // duplicate, transient or unreachable — retried on next foreground anyway
                logger?.log(level: .error, message: "Resubmit not delivered: \(txId) | \(outcome)")
            }
        }
    }

    static func isResubmissionCandidate(isSentTransaction: Bool, minedHeight: BlockHeight?, hasRaw: Bool, expiryHeight: BlockHeight?, latestHeight: BlockHeight) -> Bool {
        guard isSentTransaction, minedHeight == nil, hasRaw,
              let expiryHeight, expiryHeight > 0
        else {
            return false
        }
        // Unknown height (0) rejects: the caller defers resubmission until the first sync
        // state with a real height (resubmitWhenHeightIsAvailable), so nothing is lost.
        return latestHeight > 0 && expiryHeight > latestHeight
    }

    static func isTerminalRejection(_ outcome: TransactionSubmissionOutcome) -> Bool {
        if case let .rejected(code, _) = outcome {
            return code == terminalNodeRejectionCode
        }
        return false
    }
}
