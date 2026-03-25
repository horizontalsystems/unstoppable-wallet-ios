import Combine
import Foundation
import RxSwift
import SolanaKit

class SolanaAdapter {
    private let solanaKit: SolanaKit.Kit
    private var cancellables = Set<AnyCancellable>()

    private let balanceStateSubject = PublishSubject<AdapterState>()
    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
        }
    }

    private let balanceDataSubject = PublishSubject<BalanceData>()
    private(set) var balanceData: BalanceData {
        didSet {
            balanceDataSubject.onNext(balanceData)
        }
    }

    init(solanaKit: SolanaKit.Kit) {
        self.solanaKit = solanaKit

        balanceState = Self.adapterState(kitSyncState: solanaKit.syncState)
        balanceData = BalanceData(balance: solanaKit.balance)

        solanaKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        solanaKit.balancePublisher
            .sink { [weak self] in self?.balanceData = BalanceData(balance: $0) }
            .store(in: &cancellables)
    }
}

extension SolanaAdapter: IBaseAdapter {
    var isMainNet: Bool {
        solanaKit.isMainnet
    }
}

extension SolanaAdapter: IAdapter {
    func start() {
        // started via SolanaKitManager
    }

    func stop() {
        // stopped via SolanaKitManager
    }

    func refresh() {
        // refreshed via SolanaKitManager
    }

    var statusInfo: [(String, Any)] {
        solanaKit.statusInfo()
    }

    var debugInfo: String {
        ""
    }
}

extension SolanaAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension SolanaAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(solanaKit.address)
    }
}

extension SolanaAdapter: ISendSolanaAdapter {
    var fee: Decimal {
        SolanaKit.Kit.fee
    }

    func sendSol(toAddress: String, amount: Decimal, signer: SolanaKit.Signer) async throws {
        let lamports = Self.lamports(from: amount)
        _ = try await solanaKit.sendSol(toAddress: toAddress, amount: lamports, signer: signer)
    }

    func sendSpl(mintAddress: String, toAddress: String, amount: Decimal, decimals: Int, signer: SolanaKit.Signer) async throws {
        let rawAmount = Self.rawAmount(from: amount, decimals: decimals)
        _ = try await solanaKit.sendSpl(mintAddress: mintAddress, toAddress: toAddress, amount: rawAmount, signer: signer)
    }

    func sendRawTransaction(rawTransaction: Data, signer: SolanaKit.Signer) async throws {
        _ = try await solanaKit.sendRawTransaction(rawTransaction: rawTransaction, signer: signer)
    }

    func estimateFee(rawTransaction: Data) throws -> Decimal {
        try SolanaKit.Kit.estimateFee(rawTransaction: rawTransaction)
    }
}

extension SolanaAdapter {
    /// Converts a SOL amount (in SOL) to lamports (UInt64).
    static func lamports(from amount: Decimal) -> UInt64 {
        let lamportsPerSol: Decimal = 1_000_000_000
        let result = amount * lamportsPerSol
        return UInt64(truncating: NSDecimalNumber(decimal: result))
    }

    /// Converts lamports (UInt64) back to a SOL Decimal.
    static func decimal(lamports: UInt64) -> Decimal {
        let lamportsPerSol: Decimal = 1_000_000_000
        return Decimal(lamports) / lamportsPerSol
    }

    /// Converts a token UI amount to raw token units given the token's decimal places.
    static func rawAmount(from amount: Decimal, decimals: Int) -> UInt64 {
        let multiplier = Decimal(sign: .plus, exponent: decimals, significand: 1)
        let result = amount * multiplier
        return UInt64(truncating: NSDecimalNumber(decimal: result))
    }

    private static func adapterState(kitSyncState: SolanaKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }
}
