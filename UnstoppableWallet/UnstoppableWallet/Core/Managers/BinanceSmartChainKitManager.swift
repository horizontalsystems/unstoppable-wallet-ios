import RxSwift
import EthereumKit
import Erc20Kit
import UniswapKit

class BinanceSmartChainKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var evmKit: EthereumKit.Kit?

    private var currentAccount: Account?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func evmKit(account: Account) throws -> EthereumKit.Kit {
        if let evmKit = evmKit, let currentAccount = currentAccount, currentAccount == account {
            return evmKit
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        guard let syncSource = EthereumKit.Kit.defaultBscHttpSyncSource() else {
            throw AdapterError.wrongParameters
        }

        let evmKit = try EthereumKit.Kit.instance(
                seed: seed,
                networkType: networkType,
                syncSource: syncSource,
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

    var networkType: NetworkType {
        .bscMainNet
    }

    var statusInfo: [(String, Any)]? {
        evmKit?.statusInfo()
    }

}
