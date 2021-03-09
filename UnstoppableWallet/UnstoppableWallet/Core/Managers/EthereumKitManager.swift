import RxSwift
import EthereumKit
import Erc20Kit
import UniswapKit

class EthereumKitManager {
    weak var ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager?

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

        guard case let .mnemonic(words, _) = account.type, words.count == 12 else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: NetworkType = appConfigProvider.testMode ? .ropsten : .ethMainNet

        guard let syncSource = EthereumKit.Kit.infuraWebsocketSyncSource(networkType: networkType, projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret) else {
            throw AdapterError.wrongParameters
        }

        let evmKit = try EthereumKit.Kit.instance(
                words: words,
                networkType: networkType,
                syncSource: syncSource,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: account.id,
                minLogLevel: .error
        )

        evmKit.add(decorator: Erc20Kit.Kit.getDecorator())
        evmKit.add(decorator: UniswapKit.Kit.getDecorator())

        evmKit.start()

        self.evmKit = evmKit
        currentAccount = account

        return evmKit
    }

    var statusInfo: [(String, Any)]? {
        evmKit?.statusInfo()
    }

}
