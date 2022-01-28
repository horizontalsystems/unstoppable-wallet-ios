import RxSwift
import RxRelay
import EthereumKit
import HdWalletKit

protocol INftProvider {
    func collectionsSingle(address: String) -> Single<[NftCollection]>
}

class NftManager {
    private let accountManager: IAccountManager
    private let storage: NftStorage
    private let provider: INftProvider
    private let disposeBag = DisposeBag()
    private var providerDisposeBag = DisposeBag()

    private let collectionsRelay = PublishRelay<[NftCollection]>()

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

        provider.collectionsSingle(address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] collections in
                    self?.handle(collections: collections, account: account)
                })
                .disposed(by: providerDisposeBag)
    }

    private func handle(collections: [NftCollection], account: Account) {
        collectionsRelay.accept(collections)
        try? storage.save(collections: collections, accountId: account.id)
    }

    private func collectionsFromStorage(account: Account) -> [NftCollection] {
        do {
            return try storage.collections(accountId: account.id)
        } catch {
            return []
        }
    }

}

extension NftManager {

    var collectionsObservable: Observable<[NftCollection]> {
        collectionsRelay.asObservable()
    }

    func collections() -> [NftCollection] {
        guard let account = accountManager.activeAccount else {
            return []
        }

        return collectionsFromStorage(account: account)
    }

}
