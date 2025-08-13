import BigInt
import Combine
import Foundation
import RxSwift
import TonKit
import TonSwift

class JettonAdapter {
    private let tonKit: TonKit.Kit
    private let address: TonSwift.Address
    private var cancellables = Set<AnyCancellable>()

    private let balanceStateSubject = PublishSubject<AdapterState>()
    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
        }
    }

    private let jettonBalanceSubject = PublishSubject<JettonBalance?>()
    private(set) var jettonBalance: JettonBalance? {
        didSet {
            jettonBalanceSubject.onNext(jettonBalance)
        }
    }

    private let transactionRecordsSubject = PublishSubject<[TonTransactionRecord]>()

    init(tonKit: TonKit.Kit, address: String) throws {
        self.tonKit = tonKit
        self.address = try TonSwift.Address.parse(address)

        balanceState = Self.adapterState(kitSyncState: tonKit.jettonSyncState)
        jettonBalance = tonKit.jettonBalanceMap[self.address]

        tonKit.jettonSyncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        tonKit.jettonBalanceMapPublisher
            .sink { [weak self] in self?.handle(jettonBalanceMap: $0) }
            .store(in: &cancellables)
    }

    private func handle(jettonBalanceMap: [TonSwift.Address: JettonBalance]) {
        jettonBalance = jettonBalanceMap[address]
    }

    private static func adapterState(kitSyncState: TonKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error.localizedDescription)
        }
    }

    private static func amount(jettonBalance: JettonBalance?) -> Decimal {
        guard let jettonBalance, let significand = Decimal(string: jettonBalance.balance.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -jettonBalance.jetton.decimals, significand: significand)
    }

    private static func amount(kitAmount: BigUInt, decimals: Int) -> Decimal {
        guard let significand = Decimal(string: kitAmount.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}

extension JettonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension JettonAdapter: IAdapter {
    func start() {
        // started via TonKitManager
    }

    func stop() {
        // stopped via TonKitManager
    }

    func refresh() {
        // refreshed via TonKitManager
    }

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        ""
    }
}

extension JettonAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceData: BalanceData {
        BalanceData(balance: Self.amount(jettonBalance: jettonBalance))
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        jettonBalanceSubject.map { BalanceData(balance: Self.amount(jettonBalance: $0)) }
    }
}

extension JettonAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(tonKit.receiveAddress.toString(testOnly: TonKitManager.isTestNet, bounceable: false))
    }
}

extension JettonAdapter: ISendTonAdapter {
    func transferData(recipient: FriendlyAddress, amount: TonAdapter.SendAmount, comment: String?) throws -> TransferData {
        guard let jettonBalance else {
            throw SendError.noJettonBalance
        }

        return try tonKit.transferData(jettonAddress: jettonBalance.jettonAddress, recipient: recipient, amount: sendAmount(jettonBalance: jettonBalance, amount: amount), comment: comment)
    }

    private func sendAmount(jettonBalance: JettonBalance, amount: TonAdapter.SendAmount) throws -> BigUInt {
        switch amount {
        case let .amount(value):
            guard let value = BigUInt(value.hs.roundedString(decimal: jettonBalance.jetton.decimals)) else {
                throw AmountError.invalidAmount
            }

            return value
        case .max:
            throw AmountError.invalidAmount
        }
    }
}

extension JettonAdapter {
    enum SendError: Error {
        case noJettonBalance
    }

    enum AmountError: Error {
        case invalidAmount
    }
}
