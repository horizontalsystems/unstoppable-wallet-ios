import Combine
import Foundation
import RxSwift
import SolanaKit

class SplAdapter {
    private let solanaKit: SolanaKit.Kit
    private let mintAddress: String
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

    init(solanaKit: SolanaKit.Kit, mintAddress: String) {
        self.solanaKit = solanaKit
        self.mintAddress = mintAddress

        balanceState = Self.adapterState(kitSyncState: solanaKit.tokenBalanceSyncState)
        balanceData = BalanceData(balance: Self.balance(fullAccount: solanaKit.fullTokenAccount(mintAddress: mintAddress)))

        solanaKit.tokenBalanceSyncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        solanaKit.fungibleTokenAccountsPublisher
            .compactMap { $0.first { $0.tokenAccount.mintAddress == mintAddress } }
            .sink { [weak self] in self?.balanceData = BalanceData(balance: Self.balance(fullAccount: $0)) }
            .store(in: &cancellables)
    }
}

private extension SplAdapter {
    static func adapterState(kitSyncState: SolanaKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }

    static func balance(fullAccount: FullTokenAccount?) -> Decimal {
        guard let fullAccount else { return 0 }
        return Decimal(sign: .plus, exponent: -fullAccount.tokenAccount.decimals, significand: fullAccount.tokenAccount.decimalBalance)
    }
}

extension SplAdapter: IBaseAdapter {
    var isMainNet: Bool {
        solanaKit.isMainnet
    }
}

extension SplAdapter: IAdapter {
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

extension SplAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension SplAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(solanaKit.address)
    }
}

extension SplAdapter: ISendSolanaAdapter {
    var fee: Decimal {
        SolanaKit.Kit.fee
    }

    func sendSol(toAddress: String, amount: Decimal, signer: SolanaKit.Signer) async throws -> FullTransaction {
        let lamports = SolanaAdapter.lamports(from: amount)
        return try await solanaKit.sendSol(toAddress: toAddress, amount: lamports, signer: signer)
    }

    func sendSpl(mintAddress: String, toAddress: String, amount: Decimal, decimals: Int, signer: SolanaKit.Signer) async throws -> FullTransaction {
        let rawAmount = SolanaAdapter.rawAmount(from: amount, decimals: decimals)
        return try await solanaKit.sendSpl(mintAddress: mintAddress, toAddress: toAddress, amount: rawAmount, signer: signer)
    }

    func sendRawTransaction(rawTransaction: Data, signer: SolanaKit.Signer) async throws -> FullTransaction {
        try await solanaKit.sendRawTransaction(rawTransaction: rawTransaction, signer: signer)
    }

    func estimateFee(rawTransaction: Data) throws -> Decimal {
        try SolanaKit.Kit.estimateFee(rawTransaction: rawTransaction)
    }
}
