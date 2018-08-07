import Foundation
import RxSwift
import RealmSwift

public class SyncManager {
    public static let shared = SyncManager()

    public enum SyncStatus {
        case syncing
        case synced
        case error
    }

    private let disposeBag = DisposeBag()

    public let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
    }

    init() {
//        let unspentOutputs = realm.objects(TransactionOutput.self)
//                .filter("isMine = %@", true)
//                .filter("inputs.@count == %@", 0)
//
//        var balance = 0
//
//        for output in unspentOutputs {
//            balance += output.value
//            print("OUTPUT: \(output.value) -- \(output.transaction.reversedHashHex)")
//        }
//
//        print("Balance: \(Double(balance) / 100000000)")
    }

    public func showRealmInfo() {
        let realm = RealmFactory.shared.realm
        let blockCount = realm.objects(Block.self).count
        let addressCount = realm.objects(Address.self).count

        print("BLOCK COUNT: \(blockCount)")
        if let block = realm.objects(Block.self).first {
            print("First Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }
        if let block = realm.objects(Block.self).last {
            print("Last Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }

        print("ADDRESS COUNT: \(addressCount)")
        if let address = realm.objects(Address.self).first {
            print("First Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
        if let address = realm.objects(Address.self).last {
            print("Last Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
    }

    public func connectToPeer() {
        WalletKitProvider.shared.preFillInitialTestData()
        _ = BlockSyncer.shared
        PeerGroup.shared.connect()
    }

    private func initialSync() {
        status = .syncing

    }

}
