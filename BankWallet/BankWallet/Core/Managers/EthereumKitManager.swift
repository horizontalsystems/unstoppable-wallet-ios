import RxSwift
import HSEthereumKit

protocol IEthereumKitManager {
    func ethereumKit(authData: AuthData) -> EthereumKit
    func clear() throws
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

    func ethereumKit(authData: AuthData) -> EthereumKit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }
        let network: EthereumKit.NetworkType = appConfigProvider.testMode ? .testNet : .mainNet

        let ethereumKit = EthereumKit(withWords: authData.words, networkType: network, walletId: authData.walletId, infuraKey: appConfigProvider.infuraKey, etherscanKey: appConfigProvider.etherscanKey)
        ethereumKit.start()
        self.ethereumKit = ethereumKit
        return ethereumKit
    }

    func clear() throws {
        try ethereumKit?.clear()
    }

}
