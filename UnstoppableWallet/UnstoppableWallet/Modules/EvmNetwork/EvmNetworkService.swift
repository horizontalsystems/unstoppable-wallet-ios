import RxSwift
import RxRelay

class EvmNetworkService {
    let blockchain: EvmNetworkModule.Blockchain
    private let account: Account
    private let evmNetworkManager: EvmNetworkManager
    private let accountSettingManager: AccountSettingManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(blockchain: EvmNetworkModule.Blockchain, account: Account, evmNetworkManager: EvmNetworkManager, accountSettingManager: AccountSettingManager) {
        self.blockchain = blockchain
        self.account = account
        self.evmNetworkManager = evmNetworkManager
        self.accountSettingManager = accountSettingManager

        syncItems()
    }

    private func syncItems() {
        let currentNetwork = currentNetwork

        items = networks.map { network in
            Item(
                    network: network,
                    mainNet: network.networkType.isMainNet,
                    selected: network.id == currentNetwork.id
            )
        }
    }

    private var networks: [EvmNetwork] {
        switch blockchain {
        case .ethereum: return evmNetworkManager.ethereumNetworks
        case .binanceSmartChain: return evmNetworkManager.binanceSmartChainNetworks
        }
    }

    private var currentNetwork: EvmNetwork {
        switch blockchain {
        case .ethereum: return accountSettingManager.ethereumNetwork(account: account)
        case .binanceSmartChain: return accountSettingManager.binanceSmartChainNetwork(account: account)
        }
    }

}

extension EvmNetworkService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func setCurrentNetwork(id: String) {
        let networks = items.map { $0.network }

        guard let network = networks.first(where: { $0.id == id }) else {
            return
        }

        switch blockchain {
        case .ethereum: accountSettingManager.save(ethereumNetwork: network, account: account)
        case .binanceSmartChain: accountSettingManager.save(binanceSmartChainNetwork: network, account: account)
        }
    }

}

extension EvmNetworkService {

    struct Item {
        let network: EvmNetwork
        let mainNet: Bool
        let selected: Bool
    }

}
