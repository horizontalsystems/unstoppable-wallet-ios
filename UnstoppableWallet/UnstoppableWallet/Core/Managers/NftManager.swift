import Foundation
import RxSwift
import RxRelay
import EthereumKit
import HdWalletKit

protocol INftProvider {
    func assetCollectionSingle(address: String) -> Single<NftAssetCollection>
    func collectionStatsSingle(uid: String) -> Single<NftCollectionStats>
    func assetOrdersSingle(contractAddress: String, tokenId: String) -> Single<[NftAssetOrder]>
}

class NftManager {
    private let accountManager: IAccountManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let storage: NftStorage
    private let provider: INftProvider
    private let disposeBag = DisposeBag()
    private var providerDisposeBag = DisposeBag()

    private let assetCollectionRelay = PublishRelay<NftAssetCollection>()

    init(accountManager: IAccountManager, evmBlockchainManager: EvmBlockchainManager, storage: NftStorage, provider: INftProvider) {
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
        self.storage = storage
        self.provider = provider

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] in self?.sync(activeAccount: $0) }

        sync(activeAccount: accountManager.activeAccount)
    }

    private func sync(activeAccount: Account?) {
        guard let account = activeAccount else {
            return
        }

        do {
            let address: EthereumKit.Address

            switch account.type {
            case let .mnemonic(words, salt):
                let seed = Mnemonic.seed(mnemonic: words, passphrase: salt)
                let chain = evmBlockchainManager.chain(blockchain: .ethereum)
                address = try Signer.address(seed: seed, chain: chain)
            case let .address(value):
                address = value
            default:
                throw AdapterError.unsupportedAccount
            }

            update(account: account, address: address.hex)
        } catch {
        }
    }

    private func update(account: Account, address: String) {
        providerDisposeBag = DisposeBag()

        provider.assetCollectionSingle(address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] assetCollection in
                    self?.handle(assetCollection: assetCollection, account: account)
                })
                .disposed(by: providerDisposeBag)
    }

    private func handle(assetCollection: NftAssetCollection, account: Account) {
        assetCollectionRelay.accept(assetCollection)

        do {
            try storage.save(assetCollection: assetCollection, accountId: account.id)
        } catch {
            print("Failed to save asset collection: \(error)")
        }
    }

}

extension NftManager {

    var assetCollectionObservable: Observable<NftAssetCollection> {
        assetCollectionRelay.asObservable()
    }

    func assetCollection() -> NftAssetCollection {
        guard let account = accountManager.activeAccount else {
            return .empty
        }

        do {
            return try storage.assetCollection(accountId: account.id)
        } catch {
            return .empty
        }
    }

    func collection(uid: String) -> NftCollection? {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        do {
            return try storage.collection(accountId: account.id, uid: uid)
        } catch {
            return nil
        }
    }

    func asset(collectionUid: String, tokenId: String) -> NftAsset? {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        do {
            return try storage.asset(accountId: account.id, collectionUid: collectionUid, tokenId: tokenId)
        } catch {
            return nil
        }
    }

    func collectionStatsSingle(uid: String) -> Single<NftCollectionStats> {
        provider.collectionStatsSingle(uid: uid)
    }

    func assetOrdersSingle(contractAddress: String, tokenId: String) -> Single<[NftAssetOrder]> {
        provider.assetOrdersSingle(contractAddress: contractAddress, tokenId: tokenId)
    }

}
