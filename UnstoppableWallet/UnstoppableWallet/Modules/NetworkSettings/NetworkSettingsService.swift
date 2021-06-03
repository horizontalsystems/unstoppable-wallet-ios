import RxSwift
import RxRelay

class NetworkSettingsService {
    let account: Account
    private let accountSettingManager: AccountSettingManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(account: Account, accountSettingManager: AccountSettingManager) {
        self.account = account
        self.accountSettingManager = accountSettingManager

        subscribe(disposeBag, accountSettingManager.ethereumNetworkObservable) { [weak self] account, _ in self?.handleSettingsUpdated(account: account) }
        subscribe(disposeBag, accountSettingManager.binanceSmartChainNetworkObservable) { [weak self] account, _ in self?.handleSettingsUpdated(account: account) }

        syncItems()
    }

    private func evmItem(blockchain: Blockchain, evmNetwork: EvmNetwork) -> Item {
        Item(blockchain: blockchain, value: evmNetwork.name)
    }

    private func handleSettingsUpdated(account: Account) {
        guard account == self.account else {
            return
        }

        syncItems()
    }

    private func syncItems() {
        items = [
            evmItem(blockchain: .ethereum, evmNetwork: accountSettingManager.ethereumNetwork(account: account)),
            evmItem(blockchain: .binanceSmartChain, evmNetwork: accountSettingManager.binanceSmartChainNetwork(account: account))
        ]
    }

}

extension NetworkSettingsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

}

extension NetworkSettingsService {

    enum Blockchain {
        case ethereum
        case binanceSmartChain
    }

    struct Item {
        let blockchain: Blockchain
        let value: String
    }

}
