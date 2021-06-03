import RxSwift
import RxRelay
import EthereumKit

class AccountSettingManager {
    private let storage: IAccountSettingRecordStorage
    private let evmNetworkManager: EvmNetworkManager

    private let ethereumNetworkKey = "ethereum-network"
    private let binanceSmartChainNetworkKey = "binance-smart-chain-network"

    private let ethereumNetworkRelay = PublishRelay<(Account, EvmNetwork)>()
    private let binanceSmartChainNetworkRelay = PublishRelay<(Account, EvmNetwork)>()

    init(storage: IAccountSettingRecordStorage, evmNetworkManager: EvmNetworkManager) {
        self.storage = storage
        self.evmNetworkManager = evmNetworkManager
    }

    private func evmNetwork(account: Account, networks: [EvmNetwork], key: String) -> EvmNetwork {
        if let setting = storage.accountSetting(accountId: account.id, key: key), let network = networks.first(where: { $0.id == setting.value }) {
            return network
        }

        return networks[0]
    }

    private func save(network: EvmNetwork, account: Account, key: String) {
        let record = AccountSettingRecord(accountId: account.id, key: key, value: network.id)
        storage.save(accountSetting: record)
    }

}

extension AccountSettingManager {

    var ethereumNetworkObservable: Observable<(Account, EvmNetwork)> {
        ethereumNetworkRelay.asObservable()
    }

    var binanceSmartChainNetworkObservable: Observable<(Account, EvmNetwork)> {
        binanceSmartChainNetworkRelay.asObservable()
    }

    func ethereumNetwork(account: Account) -> EvmNetwork {
        evmNetwork(account: account, networks: evmNetworkManager.ethereumNetworks, key: ethereumNetworkKey)
    }

    func save(ethereumNetwork: EvmNetwork, account: Account) {
        save(network: ethereumNetwork, account: account, key: ethereumNetworkKey)
        ethereumNetworkRelay.accept((account, ethereumNetwork))
    }

    func binanceSmartChainNetwork(account: Account) -> EvmNetwork {
        evmNetwork(account: account, networks: evmNetworkManager.binanceSmartChainNetworks, key: binanceSmartChainNetworkKey)
    }

    func save(binanceSmartChainNetwork: EvmNetwork, account: Account) {
        save(network: binanceSmartChainNetwork, account: account, key: binanceSmartChainNetworkKey)
        binanceSmartChainNetworkRelay.accept((account, binanceSmartChainNetwork))
    }

}
