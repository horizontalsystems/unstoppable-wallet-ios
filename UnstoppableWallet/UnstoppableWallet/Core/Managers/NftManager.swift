import Foundation
import RxSwift
import RxRelay
import EthereumKit
import HdWalletKit

protocol INftProvider {
    func assetCollectionSingle(address: String) -> Single<NftAssetCollection>
    func collectionStatsSingle(slug: String) -> Single<NftCollectionStats>
}

class NftManager {
    private let accountManager: IAccountManager
    private let storage: NftStorage
    private let provider: INftProvider
    private let disposeBag = DisposeBag()
    private var providerDisposeBag = DisposeBag()

    private let assetCollectionRelay = PublishRelay<NftAssetCollection>()

    init(accountManager: IAccountManager, storage: NftStorage, provider: INftProvider) {
        self.accountManager = accountManager
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
                address = try Signer.address(seed: seed, networkType: .ethMainNet)
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

    func collection(slug: String) -> NftCollection? {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        do {
            return try storage.collection(accountId: account.id, slug: slug)
        } catch {
            return nil
        }
    }

    func asset(collectionSlug: String, tokenId: String) -> NftAsset? {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        do {
            return try storage.asset(accountId: account.id, collectionSlug: collectionSlug, tokenId: tokenId)
        } catch {
            return nil
        }
    }

    func collectionStatsSingle(slug: String) -> Single<NftCollectionStats> {
        provider.collectionStatsSingle(slug: slug)
    }

}
