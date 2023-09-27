import Foundation
import TronKit
import RxSwift
import BigInt
import HsToolKit
import MarketKit

class Trc20Adapter: BaseTronAdapter {
    private let contractAddress: TronKit.Address

    init(tronKitWrapper: TronKitWrapper, contractAddress: String, wallet: Wallet) throws {
        self.contractAddress = try TronKit.Address(address: contractAddress)

        super.init(tronKitWrapper: tronKitWrapper, decimals: wallet.decimals)
    }

}

// IAdapter
extension Trc20Adapter: IAdapter {

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

extension Trc20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(tronSyncState: tronKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        tronKit.syncStatePublisher.asObservable().map { [weak self] in
            self?.convertToAdapterState(tronSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(balance: tronKit.trc20Balance(contractAddress: contractAddress))
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        tronKit.trc20BalancePublisher(contractAddress: contractAddress).asObservable().map { [weak self] in
            self?.balanceData(balance: $0) ?? BalanceData(available: 0)
        }
    }

}

extension Trc20Adapter: ISendTronAdapter {

    func contract(amount: BigUInt, address: TronKit.Address) -> Contract {
        tronKit.transferTrc20TriggerSmartContract(contractAddress: contractAddress, toAddress: address, amount: amount)
    }

}
