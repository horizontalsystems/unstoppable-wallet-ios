import CryptoKit
import Foundation
import stellarsdk

/// Runs ONE StellarBroker interactive trade over its WebSocket protocol
/// (`wss://api.stellar.broker/ws?partner=<key>`): request a live quote, confirm it, then sign
/// each broker-built transaction the server streams — the BROKER submits them, the client only
/// signs. Mirrors the reference `@stellar-broker/client` (see
/// ~/docs/knowledge/providers/STELLARBROKER_API.md for the message-by-message protocol).
///
/// The user has already confirmed the swap in the wallet UI (against the committed /v2/swap
/// snapshot), so the session auto-confirms the first fresh `success` quote it receives — the
/// broker re-prices live but is bound by `slippageTolerance` from the quote request.
class StellarBrokerSessionClient: NSObject {
    private static let origin = "wss://api.stellar.broker/ws"
    private static let connectTimeout: TimeInterval = 5
    private static let quoteTimeout: TimeInterval = 15
    // Full-trade ceiling: SB splits a trade over several sequential txs (~5s ledgers each).
    private static let tradeTimeout: TimeInterval = 180
    // The reference client closes the socket after 7s without a server ping; be a bit lenient.
    private static let heartbeatTimeout: TimeInterval = 20

    struct Params {
        let sellingAsset: String // SB wire form: "XLM" | "CODE-GISSUER…"
        let buyingAsset: String
        let sellingAmount: String // whole units, decimal string
        let slippageTolerance: Double // fraction, 0–0.5
        let partnerKey: String?
    }

    struct TradeResult {
        let sold: Decimal?
        let bought: Decimal?
        // Fee-bump hashes of every tx WE signed, in order. The last one is reported to
        // uswap-server as `inboundTxHash` (StellarTracker verifies it on Horizon).
        let txHashes: [String]
    }

    enum SessionError: Error, LocalizedError {
        case invalidUrl
        case connectTimeout
        case quoteTimeout
        case quoteNotAvailable(String?)
        case invalidSwapTx
        case debitLimitExceeded
        case tradeFailed(String?)
        case serverError(String)
        case socketClosed

        var errorDescription: String? {
            switch self {
            case .invalidUrl: return "StellarBroker: invalid URL"
            case .connectTimeout: return "StellarBroker: connection timed out"
            case .quoteTimeout: return "StellarBroker: no quote received"
            case let .quoteNotAvailable(message): return "StellarBroker: quote not available\(message.map { ": \($0)" } ?? "")"
            case .invalidSwapTx: return "StellarBroker: invalid swap transaction received"
            case .debitLimitExceeded: return "StellarBroker: transaction would spend more than the confirmed amount"
            case let .tradeFailed(status): return "StellarBroker: trade failed\(status.map { " (\($0))" } ?? "")"
            case let .serverError(message): return "StellarBroker: \(message)"
            case .socketClosed: return "StellarBroker: connection closed"
            }
        }
    }

    /// A trade-phase failure AFTER txs were signed (and possibly submitted by the broker):
    /// value may already have moved on-chain. Carries the signed hashes + last progress so
    /// the send handler persists a trackable swap record — the server's StellarTracker then
    /// resolves the REAL outcome on Horizon (partial fills included) instead of the swap
    /// becoming an untracked ghost stuck pending forever.
    struct SessionFailure: Error, LocalizedError, IPartialExecutionError {
        let underlying: Error
        let txHashes: [String]
        let sold: Decimal?
        let bought: Decimal?

        var partialTxHash: String? { txHashes.last }
        var errorDescription: String? { (underlying as? LocalizedError)?.errorDescription ?? String(describing: underlying) }
    }

    private let trader: String
    private let keyPair: KeyPair
    private let params: Params

    // Debit budget: the trader's cumulative signed debits (classic path-payment spends +
    // Soroban SAC transfers authorized by the trader) may never exceed the CONFIRMED sell
    // amount plus small headroom for the broker's on-chain fee leg and rounding. This turns
    // "trust the broker completely" into "trust the broker up to the confirmed amount" —
    // a compromised broker can no longer stream txs draining the seller's balance.
    private static let debitHeadroom = Decimal(string: "1.02")!
    private let sellingAsset: Asset?
    private let sellingSacHex: String? // the selling asset's SAC contract id (hex)
    private let maxDebit: Decimal
    private var totalDebited: Decimal = 0

    private var socket: URLSessionWebSocketTask?
    private var uid: String?
    private var signedTxHashes = [String]()
    private var lastActivity = Date()
    private var progress: (sold: Decimal?, bought: Decimal?) = (nil, nil)

    init(trader: String, keyPair: KeyPair, params: Params) {
        self.trader = trader
        self.keyPair = keyPair
        self.params = params

        let asset = Self.parseWireAsset(params.sellingAsset)
        sellingAsset = asset
        sellingSacHex = asset.flatMap { Self.sacContractIdHex(asset: $0) }
        maxDebit = (Decimal(string: params.sellingAmount) ?? 0) * Self.debitHeadroom
    }

    // MARK: - Session

    func execute() async throws -> TradeResult {
        var components = URLComponents(string: Self.origin)
        if let partnerKey = params.partnerKey, !partnerKey.isEmpty {
            components?.queryItems = [URLQueryItem(name: "partner", value: partnerKey)]
        }
        guard let url = components?.url else { throw SessionError.invalidUrl }

        let session = URLSession(configuration: .default)
        let socket = session.webSocketTask(with: url)
        self.socket = socket
        socket.resume()
        defer {
            socket.cancel(with: .normalClosure, reason: nil)
            session.finishTasksAndInvalidate()
        }

        // Phase 1 — readiness is the server's `connected{uid}` message, NOT the socket opening.
        let connected = try await nextMessage(ofType: "connected", timeout: Self.connectTimeout, timeoutError: .connectTimeout)
        uid = connected["uid"] as? String

        // Phase 2 — request a quote, wait for the first tradeable one.
        try await send([
            "type": "quote",
            "sellingAsset": params.sellingAsset,
            "buyingAsset": params.buyingAsset,
            "sellingAmount": params.sellingAmount,
            "slippageTolerance": params.slippageTolerance,
        ])

        let quoteMessage = try await nextMessage(ofType: "quote", timeout: Self.quoteTimeout, timeoutError: .quoteTimeout)
        let quote = quoteMessage["quote"] as? [String: Any] ?? quoteMessage
        guard quote["status"] as? String == "success" else {
            throw SessionError.quoteNotAvailable(quote["error"] as? String)
        }


        // Phase 3 — confirm immediately (the quote is fresh by construction; the 10s staleness
        // gate of the reference client is inherently satisfied) and process the trade stream.
        // Any failure AFTER a tx was signed is wrapped so the signed hashes survive the throw
        // (the broker may have already submitted them — see SessionFailure).
        try await send(["type": "trade", "account": trader])
        do {
            return try await runTrade()
        } catch {
            if signedTxHashes.isEmpty { throw error }
            throw SessionFailure(underlying: error, txHashes: signedTxHashes, sold: progress.sold, bought: progress.bought)
        }
    }

    private func runTrade() async throws -> TradeResult {
        let deadline = Date().addingTimeInterval(Self.tradeTimeout)
        while Date() < deadline {
            let message = try await receiveMessage(timeout: Self.heartbeatTimeout)

            switch message["type"] as? String {
            case "tx":
                guard let xdr = message["xdr"] as? String, let hash = message["hash"] else {
                    throw SessionError.invalidSwapTx
                }
                let networkFee = (message["networkFee"] as? String) ?? String(describing: message["networkFee"] ?? "200")
                let signedXdr = try processTxRequest(xdr: xdr, networkFee: networkFee)
                try await send(["type": "tx", "hash": hash, "xdr": signedXdr])

            case "progress":
                progress = (decimal(message["sold"]), decimal(message["bought"]))

            case "stop":
                let status = message["status"] as? String
                guard status == "success" else { throw SessionError.tradeFailed(status) }
                return TradeResult(
                    sold: decimal(message["sold"]) ?? progress.sold,
                    bought: decimal(message["bought"]) ?? progress.bought,
                    txHashes: signedTxHashes
                )

            case "ping":
                // Echo the pong with our uid — the server drops silent sessions.
                try await send(["type": "pong", "uid": (message["uid"] as? String) ?? uid ?? ""])

            case "quote", "paused":
                break // late re-quotes / pause notices during trading are informational

            case "error":
                throw SessionError.serverError(String(describing: message["error"] ?? "unknown"))

            default:
                break
            }
        }

        throw SessionError.tradeFailed("timeout")
    }

    // MARK: - Signing pipeline (mirror of the reference tx-processor)

    /// Sign one broker-built tx. Classic swaps: sign the inner tx, wrap it in a fee-bump paid
    /// by the trader, sign the wrapper. Soroban swaps are TWO-PHASE: the first pass signs the
    /// auth entries + the inner tx and returns it WITHOUT a fee bump (the server round-trips
    /// it); the second pass (already-signed tx) only wraps + signs the fee bump.
    private func processTxRequest(xdr: String, networkFee: String) throws -> String {
        let network = Network.public
        let transaction = try Transaction(envelopeXdr: xdr)

        guard validate(transaction: transaction) else {
            throw SessionError.invalidSwapTx
        }

        let sorobanAuthCount = transaction.operations
            .compactMap { $0 as? InvokeHostFunctionOperation }
            .reduce(0) { $0 + $1.auth.count }
        let isSoroban = sorobanAuthCount > 0
        let alreadySigned = !transaction.transactionXDR.signatures.isEmpty

        // Debit budget check — ONCE per tx (the Soroban round-trip re-sends the same tx
        // signed for its fee bump; counting it twice would falsely trip the limit).
        if !alreadySigned {
            let debit = try tradeDebit(transaction: transaction)
            guard totalDebited + debit <= maxDebit else { throw SessionError.debitLimitExceeded }
            totalDebited += debit
        }

        if isSoroban, !alreadySigned {
            // Phase 1: sign the Soroban auth entries (expiring just past the tx's ledger
            // bounds, like the reference client), then the inner tx — NO fee bump yet.
            let expirationLedger = transaction.preconditions?.ledgerBounds.map { $0.maxLedger + 1 }
            for operation in transaction.operations {
                guard let invoke = operation as? InvokeHostFunctionOperation else { continue }
                var entries = invoke.auth
                for index in entries.indices {
                    try entries[index].sign(signer: keyPair, network: network, signatureExpirationLedger: expirationLedger)
                }
                invoke.auth = entries
            }
            try transaction.sign(keyPair: keyPair, network: network)
            return try transaction.encodedEnvelope()
        }

        if !isSoroban {
            try transaction.sign(keyPair: keyPair, network: network)
        }

        // Wrap with a fee bump paid by the trader and sign the wrapper.
        let fee = UInt64(networkFee) ?? 1000
        let feeBump = try FeeBumpTransaction(
            sourceAccount: MuxedAccount(accountId: trader),
            fee: fee,
            innerTransaction: transaction
        )
        // (MuxedAccount(accountId:) is throwing — covered by the enclosing `try`.)
        try feeBump.sign(keyPair: keyPair, network: network)

        if let hash = try? feeBump.getTransactionHash(network: network) {
            signedTxHashes.append(hash)
        }

        return try feeBump.encodedEnvelope()
    }

    /// The reference client's safety check: every operation must be a path payment that either
    /// pays the TRADER (the swap leg) or is a strict-send fee leg sourced from the trader
    /// (the broker's cut). Soroban invocations pass through (validated by simulation).
    private func validate(transaction: Transaction) -> Bool {
        for operation in transaction.operations {
            if operation is InvokeHostFunctionOperation {
                continue
            }

            let destination: String
            let isStrictSend: Bool
            if let op = operation as? PathPaymentStrictSendOperation {
                destination = op.destinationAccountId
                isStrictSend = true
            } else if let op = operation as? PathPaymentStrictReceiveOperation {
                destination = op.destinationAccountId
                isStrictSend = false
            } else if let op = operation as? PathPaymentOperation {
                destination = op.destinationAccountId
                isStrictSend = false
            } else {
                return false
            }

            let source = operation.sourceAccountId
            if destination != trader {
                // Fee leg: strict-send only, and never spending from a foreign source.
                guard isStrictSend, source == nil || source == trader else { return false }
            } else {
                guard source == nil || source == destination else { return false }
            }
        }
        return true
    }

    /// The tx's total trader debit in SELLING-asset units, throwing on anything a legitimate
    /// SB trade never contains. Classic legs: every trader-sourced path payment must spend
    /// the selling asset (network fees ride the fee bump in XLM), and its sendMax (exact for
    /// strict-send, enforced cap otherwise) counts toward the budget. Soroban legs: every
    /// auth entry we're about to sign is walked — a `transfer` FROM the trader must be on the
    /// selling asset's SAC with a sane bounded amount; allowance/burn functions touching the
    /// trader never appear in a swap and are rejected outright. Signing an arbitrary auth
    /// entry would otherwise authorize `transfer(trader, broker, anything)` on any SAC.
    private func tradeDebit(transaction: Transaction) throws -> Decimal {
        var debit: Decimal = 0
        for operation in transaction.operations {
            if let invoke = operation as? InvokeHostFunctionOperation {
                for entry in invoke.auth {
                    debit += try authorizedDebit(invocation: entry.rootInvocation)
                }
                continue
            }
            guard let op = operation as? PathPaymentOperation else { continue } // validate() rejected the rest
            let source = operation.sourceAccountId
            guard source == nil || source == trader else { continue } // foreign-sourced legs don't spend our funds
            guard assetsEqual(op.sendAsset, sellingAsset) else { throw SessionError.invalidSwapTx }
            debit += op.sendMax
        }
        return debit
    }

    private func authorizedDebit(invocation: SorobanAuthorizedInvocationXDR) throws -> Decimal {
        var debit: Decimal = 0
        switch invocation.function {
        case let .contractFn(args):
            let function = args.functionName
            let addressArgs = args.args.compactMap { $0.address?.accountId }
            if function == "transfer", args.args.first?.address?.accountId == trader {
                // SEP-41 transfer(from, to, amount) funded by the trader: selling-asset SAC only.
                guard let sacHex = sellingSacHex,
                      args.contractAddress.contractId?.lowercased() == sacHex,
                      args.args.count == 3,
                      let amount = args.args[2].i128,
                      amount.hi == 0
                else { throw SessionError.invalidSwapTx }
                debit += Decimal(amount.lo) / 10_000_000
            } else if ["transfer_from", "approve", "burn", "burn_from"].contains(function), addressArgs.contains(trader) {
                throw SessionError.invalidSwapTx
            }
        case .createContractHostFn, .createContractV2HostFn:
            throw SessionError.invalidSwapTx
        }
        for sub in invocation.subInvocations {
            debit += try authorizedDebit(invocation: sub)
        }
        return debit
    }

    private func assetsEqual(_ a: Asset, _ b: Asset?) -> Bool {
        guard let b else { return false }
        return a.type == b.type && a.code == b.code && a.issuer?.accountId == b.issuer?.accountId
    }

    /// SB wire form → SDK asset: `XLM` (native) | `CODE-GISSUER…` (classic).
    private static func parseWireAsset(_ wire: String) -> Asset? {
        if wire == "XLM" { return Asset(type: AssetType.ASSET_TYPE_NATIVE) }
        guard let dash = wire.firstIndex(of: "-") else { return nil }
        let code = String(wire[..<dash])
        let issuerId = String(wire[wire.index(after: dash)...])
        guard !code.isEmpty, code.count <= 12, let issuer = try? KeyPair(accountId: issuerId) else { return nil }
        let type = code.count <= 4 ? AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 : AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        return Asset(type: type, code: code, issuer: issuer)
    }

    /// The asset's Stellar Asset Contract id (hex), derived locally: sha256 of the XDR-encoded
    /// `HashIDPreimage::ContractID { networkId, ContractIDPreimage::fromAsset }` — the same
    /// deterministic derivation uswap-server uses (`Asset.contractId(Networks.PUBLIC)`).
    /// Mainnet passphrase is hardcoded: SB is mainnet-only.
    private static func sacContractIdHex(asset: Asset) -> String? {
        guard let assetXdr = try? asset.toXDR() else { return nil }
        let networkId = Data(SHA256.hash(data: Data("Public Global Stellar Network ; September 2015".utf8)))
        let preimage = HashIDPreimageXDR.contractID(HashIDPreimageContractIDXDR(
            networkID: WrappedData32(networkId),
            contractIDPreimage: .fromAsset(assetXdr)
        ))
        guard let encoded = try? XDREncoder.encode(preimage) else { return nil }
        return Data(SHA256.hash(data: Data(encoded))).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Transport

    private func send(_ payload: [String: Any]) async throws {
        guard let socket else { throw SessionError.socketClosed }
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else { throw SessionError.socketClosed }
        try await socket.send(.string(text))
    }

    /// Receive one JSON message, bounded by a timeout (also our heartbeat watchdog — the
    /// server pings every few seconds, so prolonged silence means the session is dead).
    private func receiveMessage(timeout: TimeInterval) async throws -> [String: Any] {
        guard let socket else { throw SessionError.socketClosed }

        return try await withThrowingTaskGroup(of: [String: Any].self) { group in
            group.addTask {
                while true {
                    let raw = try await socket.receive()
                    let data: Data?
                    switch raw {
                    case let .string(text): data = text.data(using: .utf8)
                    case let .data(binary): data = binary
                    @unknown default: data = nil
                    }
                    guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        continue
                    }
                    return json
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw SessionError.socketClosed
            }

            guard let first = try await group.next() else { throw SessionError.socketClosed }
            group.cancelAll()
            return first
        }
    }

    /// Pump messages until one of the wanted type arrives (answering pings meanwhile).
    private func nextMessage(ofType type: String, timeout: TimeInterval, timeoutError: SessionError) async throws -> [String: Any] {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else { break }

            let message: [String: Any]
            do {
                message = try await receiveMessage(timeout: remaining)
            } catch {
                throw timeoutError
            }

            switch message["type"] as? String {
            case type:
                return message
            case "ping":
                try await send(["type": "pong", "uid": (message["uid"] as? String) ?? uid ?? ""])
            case "error":
                throw SessionError.serverError(String(describing: message["error"] ?? "unknown"))
            default:
                continue
            }
        }
        throw timeoutError
    }

    private func decimal(_ value: Any?) -> Decimal? {
        if let string = value as? String { return Decimal(string: string) }
        if let number = value as? NSNumber { return number.decimalValue }
        return nil
    }
}
