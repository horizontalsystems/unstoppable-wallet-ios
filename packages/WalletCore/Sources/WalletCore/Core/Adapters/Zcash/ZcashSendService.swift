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

    func migrationProposal(orchardBalance: Decimal) async throws -> (amount: Decimal, fee: Decimal) {
        try await migrator.migrationProposal(orchardBalance: orchardBalance)
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
        let stream = try await synchronizer.createProposedTransactions(
            proposal: proposal,
            spendingKey: spendingKey
        )

        let transactionCount = proposal.transactionCount()
        var successCount = 0
        var iterator = stream.makeAsyncIterator()

        var txIds: [String] = []
        var resubmitableFailure = false
        var submitFailure: Error?

        for _ in 1 ... transactionCount {
            if let transactionSubmitResult = try await iterator.next() {
                switch transactionSubmitResult {
                case let .success(txId: id):
                    successCount += 1
                    txIds.append(id.toHexStringTxId())
                    logger?.log(level: .debug, message: "-> Successful send TX: \(id.toHexStringTxId())")
                case let .grpcFailure(txId: id, error: error):
                    txIds.append(id.toHexStringTxId())
                    logger?.log(level: .error, message: "-> Error with send TX: \(error.localizedDescription)")
                    resubmitableFailure = true
                case let .submitFailure(txId: id, code: code, description: description):
                    txIds.append(id.toHexStringTxId())
                    logger?.log(level: .error, message: "-> Error submit TX: \(id.toHexStringTxId()) | code: \(code) | desc: \(description)")
                    submitFailure = AppError.invalidResponse(reason: "Zcash node rejected transaction (code \(code)): \(description)")
                case let .notAttempted(txId: id):
                    txIds.append(id.toHexStringTxId())
                    logger?.log(level: .error, message: "-> notAttempted TX: \(id.toHexStringTxId())")
                }
            }
        }

        if successCount == 0 {
            if resubmitableFailure {
                logger?.log(level: .debug, message: "Grpc Failure! \(txIds.count)")
            } else {
                logger?.log(level: .debug, message: "Failure sended TXs! \(txIds.count)")
            }
        } else if successCount == transactionCount {
            logger?.log(level: .debug, message: "Successful sended All TXs")
        } else {
            logger?.log(level: .debug, message: "Partial success TXs \(txIds.count)")
        }

        historyService?.reSyncPending()

        if let submitFailure {
            throw submitFailure
        }

        return txIds.first
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

            do {
                try await synchronizer.broadcaster.submit(raw, to: endpoint)
                logger?.log(level: .debug, message: "Resubmit accepted: \(txId)")
            } catch {
                if Self.isTerminalSubmitError(error) {
                    // marker first, then redacted diagnostics: no raw tx / node message is persisted
                    terminalStore.markNodeRejected(txId: txId, expiryHeight: overview.expiryHeight ?? 0)
                    logger?.log(level: .error, message: "Resubmit terminal node rejection (code \(Self.terminalNodeRejectionCode)): \(txId)")
                } else {
                    // duplicate ("already in block chain") or transient failure — retried on next foreground anyway
                    logger?.log(level: .error, message: "Resubmit not delivered: \(txId) | \(error)")
                }
            }
        }
    }

    static func isResubmissionCandidate(isSentTransaction: Bool, minedHeight: BlockHeight?, hasRaw: Bool, expiryHeight: BlockHeight?, latestHeight: BlockHeight) -> Bool {
        guard isSentTransaction, minedHeight == nil, hasRaw,
              let expiryHeight, expiryHeight > 0
        else {
            return false
        }
        return latestHeight > 0 && expiryHeight > latestHeight
    }

    static func isTerminalSubmitError(_ error: Error) -> Bool {
        if case let .submitError(code, _) = error as? TransactionEncoderError {
            return code == terminalNodeRejectionCode
        }
        return false
    }
}
