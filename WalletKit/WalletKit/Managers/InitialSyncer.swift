import Foundation
import RxSwift
import RealmSwift

class InitialSyncer {
    private let disposeBag = DisposeBag()

    private let realmFactory: RealmFactory
    private let hdWallet: HDWallet
    private let stateManager: StateManager
    private let apiManager: ApiManager
    private let peerGroup: PeerGroup

    private let gapLimit: Int

    init(realmFactory: RealmFactory, hdWallet: HDWallet, stateManager: StateManager, apiManager: ApiManager, peerGroup: PeerGroup, gapLimit: Int = 20) {
        self.realmFactory = realmFactory
        self.hdWallet = hdWallet
        self.stateManager = stateManager
        self.apiManager = apiManager
        self.peerGroup = peerGroup
        self.gapLimit = gapLimit
    }

    func sync() throws {
        if !stateManager.apiSynced {
            let maxHeight = 0

            let externalObservable = try fetchFromApi(external: true, maxHeight: maxHeight)
            let internalObservable = try fetchFromApi(external: false, maxHeight: maxHeight)

            Observable
                    .zip(externalObservable, internalObservable, resultSelector: { external, `internal` -> ([PublicKey], [Block]) in
                        let (externalKeys, externalBlocks) = external
                        let (internalKeys, internalBlocks) = `internal`

                        return (externalKeys + internalKeys, externalBlocks + internalBlocks)
                    })
                    .subscribeInBackground(disposeBag: disposeBag, onNext: { [weak self] keys, blocks in
                        try? self?.handle(keys: keys, blocks: blocks)
                    })
        } else {
            peerGroup.connect()
        }
    }

    private func handle(keys: [PublicKey], blocks: [Block]) throws {
        print("SAVING: \(keys.count) keys, \(blocks.count) blocks")

        let realm = realmFactory.realm

        try realm.write {
            realm.add(keys, update: true)
            realm.add(blocks, update: true)
        }

        stateManager.apiSynced = true
        peerGroup.connect()
    }

    private func fetchFromApi(external: Bool, maxHeight: Int, keys: [PublicKey] = [], blocks: [Block] = []) throws -> Observable<([PublicKey], [Block])> {
        let count = keys.count

        var newKeys = [PublicKey]()

        for index in count..<(count + gapLimit) {
            let key = try hdWallet.publicKey(index: index, external: external)
            newKeys.append(key)
        }

        return apiManager.getBlockHashes(addresses: newKeys.map { $0.address })
                .flatMap { blockResponses -> Observable<([PublicKey], [Block])> in
                    let keys = keys + newKeys

                    if blockResponses.isEmpty {
                        return Observable.just((keys, blocks))
                    } else {
                        let validResponses = blockResponses.filter { $0.height < maxHeight }

                        let validBlocks = validResponses.compactMap { response -> Block? in
                            if let hash = Data(hex: response.hash) {
                                return Factory().block(withHeaderHash: Data(hash.reversed()), height: response.height)
                            }
                            return nil
                        }

                        let blocks = blocks + validBlocks
                        return try self.fetchFromApi(external: external, maxHeight: maxHeight, keys: keys, blocks: blocks)
                    }
                }
    }

}
