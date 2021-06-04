import RxSwift
import RxRelay
import EthereumKit
import Erc20Kit
import UniswapKit

class BinanceSmartChainKitManager {
    private let appConfigProvider: IAppConfigProvider
    private let accountSettingsManager: AccountSettingManager
    private let disposeBag = DisposeBag()

    weak var evmKit: EthereumKit.Kit?

    private let evmKitUpdatedRelay = PublishRelay<Void>()
    private var currentAccount: Account?

    init(appConfigProvider: IAppConfigProvider, accountSettingsManager: AccountSettingManager) {
        self.appConfigProvider = appConfigProvider
        self.accountSettingsManager = accountSettingsManager

        subscribe(disposeBag, accountSettingsManager.binanceSmartChainNetworkObservable) { [weak self] account, _ in
            self?.handleUpdatedNetwork(account: account)
        }
    }

    private func handleUpdatedNetwork(account: Account) {
        guard account == currentAccount else {
            return
        }

        evmKit = nil
        evmKitUpdatedRelay.accept(())
    }

}

extension BinanceSmartChainKitManager {

    var evmKitUpdatedObservable: Observable<Void> {
        evmKitUpdatedRelay.asObservable()
    }

    func evmKit(account: Account) throws -> EthereumKit.Kit {
        if let evmKit = evmKit, let currentAccount = currentAccount, currentAccount == account {
            return evmKit
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let evmNetwork = accountSettingsManager.binanceSmartChainNetwork(account: account)

        let evmKit = try EthereumKit.Kit.instance(
                seed: seed,
                networkType: evmNetwork.networkType,
                syncSource: evmNetwork.syncSource,
                etherscanApiKey: appConfigProvider.bscscanKey,
                walletId: account.id,
                minLogLevel: .error
        )

        evmKit.add(decorator: Erc20Kit.Kit.getDecorator())
        evmKit.add(decorator: UniswapKit.Kit.getDecorator())
        evmKit.add(transactionSyncer: Erc20Kit.Kit.getTransactionSyncer(evmKit: evmKit))

        evmKit.start()

        self.evmKit = evmKit
        currentAccount = account

        return evmKit
    }

    var statusInfo: [(String, Any)]? {
        evmKit?.statusInfo()
    }

}
