import RxSwift
import HSEthereumKit

protocol IEthereumKitManager {
    func ethereumKit(authData: AuthData) throws -> EthereumKit
    func clear()
}

protocol IKitWrapper {
    var receiveAddress: String { get }
    var balance: Decimal { get }
    var fee: Decimal { get }
    var lastBlockHeight: Int? { get }
    var debugInfo: String { get }
    var decimal: Int { get }

    func start()
    func refresh()
    func clear() throws

    func validate(address: String) throws
    func send(to address: String, value: Decimal, gasPrice: Int?, completion: ((Error?) -> ())?)

    func transactions(fromHash: String?, limit: Int?) -> Single<[EthereumTransaction]>
}

class EthereumKitManager: IEthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    private weak var ethereumKit: EthereumKit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(authData: AuthData) throws -> EthereumKit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }

        let ethereumKit = try EthereumKit.ethereumKit(
                words: authData.words,
                walletId: authData.walletId,
                testMode: appConfigProvider.testMode,
                infuraKey: appConfigProvider.infuraKey,
                etherscanKey: appConfigProvider.etherscanKey
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit
        return ethereumKit
    }

    func clear() {
        ethereumKit?.clear()
    }

}
