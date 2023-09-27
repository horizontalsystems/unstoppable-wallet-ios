import TronKit
import RxSwift
import BigInt
import HsToolKit

class TronAdapter: BaseTronAdapter {
    static let decimals = 6

    init(tronKitWrapper: TronKitWrapper) {
        super.init(tronKitWrapper: tronKitWrapper, decimals: TronAdapter.decimals)
    }

}

extension TronAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try TronKit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension TronAdapter: IAdapter {

    func start() {
        // started via TronKitManager
    }

    func stop() {
        // stopped via TronKitManager
    }

    func refresh() {
        // refreshed via TronKitManager
    }

}

extension TronAdapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(tronSyncState: tronKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        tronKit.syncStatePublisher.asObservable().map { [weak self] in
            self?.convertToAdapterState(tronSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(balance: tronKit.trxBalance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        tronKit.trxBalancePublisher.asObservable().map { [weak self] in
            self?.balanceData(balance: $0) ?? BalanceData(available: 0)
        }
    }

}

extension TronAdapter: ISendTronAdapter {

    func contract(amount: BigUInt, address: TronKit.Address) -> Contract {
        tronKit.transferContract(toAddress: address, value: Int(amount))
    }

}
