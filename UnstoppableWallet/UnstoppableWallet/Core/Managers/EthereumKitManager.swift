import RxSwift
import EthereumKit
import Erc20Kit

class EthereumKitManager {
    weak var ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager?

    private let appConfigProvider: IAppConfigProvider
    weak var ethereumKit: EthereumKit.Kit?

    private var currentAccount: Account?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(account: Account) throws -> EthereumKit.Kit {
        if let ethereumKit = ethereumKit, let currentAccount = currentAccount, currentAccount == account {
            return ethereumKit
        }

        guard case let .mnemonic(words, _) = account.type, words.count == 12 else {
            throw AdapterError.unsupportedAccount
        }

        let rpcApi: SyncSource = .infuraWebSocket(id: appConfigProvider.infuraCredentials.id, secret: appConfigProvider.infuraCredentials.secret)

        let ethereumKit = try EthereumKit.Kit.instance(
                words: words,
                syncMode: .api,
                networkType: appConfigProvider.testMode ? .ropsten : .mainNet,
                rpcApi: rpcApi,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: account.id,
                minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit
        currentAccount = account

        return ethereumKit
    }

    var statusInfo: [(String, Any)]? {
        ethereumKit?.statusInfo()
    }

}
