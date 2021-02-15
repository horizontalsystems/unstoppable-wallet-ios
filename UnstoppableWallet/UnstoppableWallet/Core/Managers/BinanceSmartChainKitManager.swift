import RxSwift
import EthereumKit
import Erc20Kit

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

        guard case let .mnemonic(words, _) = account.type, words.count == 24 else {
            throw AdapterError.unsupportedAccount
        }

        guard let syncSource = EthereumKit.Kit.defaultBscWebsocketSyncSource() else {
            throw AdapterError.wrongParameters
        }

        let evmKit = try EthereumKit.Kit.instance(
                words: words,
                networkType: .bscMainNet,
                syncSource: syncSource,
                etherscanApiKey: appConfigProvider.bscscanKey,
                walletId: account.id,
                minLogLevel: .error
        )

        evmKit.start()

        self.evmKit = evmKit
        currentAccount = account

        return evmKit
    }

    var statusInfo: [(String, Any)]? {
        evmKit?.statusInfo()
    }

}
