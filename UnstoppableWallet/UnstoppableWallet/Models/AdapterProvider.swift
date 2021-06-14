import RxSwift
import RxRelay
import EthereumKit

protocol IAdapterProvider {
    func adapter() throws -> IAdapter
    var adapterInvalidatedObservable: Observable<Void> { get }
}

class BaseAdapterProvider {
    fileprivate let wallet: Wallet
    fileprivate let adapterInvalidatedRelay = PublishRelay<Void>()
    fileprivate let disposeBag = DisposeBag()

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    var adapterInvalidatedObservable: Observable<Void> {
        adapterInvalidatedRelay.asObservable()
    }

}

class BaseBitcoinAdapterProvider: BaseAdapterProvider {
    private let appConfigProvider: IAppConfigProvider
    private let initialSyncSettingsManager: InitialSyncSettingsManager

    init(wallet: Wallet, appConfigProvider: IAppConfigProvider, initialSyncSettingsManager: InitialSyncSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.initialSyncSettingsManager = initialSyncSettingsManager

        super.init(wallet: wallet)

        subscribe(disposeBag, initialSyncSettingsManager.settingUpdatedObservable) { [weak self] in self?.handleUpdated(setting: $0) }
    }

    private func handleUpdated(setting: InitialSyncSetting) {
        guard setting.coinType == wallet.coin.type, wallet.account.origin == .restored else {
            return
        }

        adapterInvalidatedRelay.accept(())
    }

    var syncMode: SyncMode {
        initialSyncSettingsManager.setting(coinType: wallet.coin.type, accountOrigin: wallet.account.origin)?.syncMode ?? .fast
    }

    var testMode: Bool {
        appConfigProvider.testMode
    }

}


class BitcoinAdapterProvider: BaseBitcoinAdapterProvider, IAdapterProvider {

    func adapter() throws -> IAdapter {
        try BitcoinAdapter(wallet: wallet, syncMode: syncMode, testMode: testMode)
    }

}

class LitecoinAdapterProvider: BaseBitcoinAdapterProvider, IAdapterProvider {

    func adapter() throws -> IAdapter {
        try LitecoinAdapter(wallet: wallet, syncMode: syncMode, testMode: testMode)
    }

}

class BitcoinCashAdapterProvider: BaseBitcoinAdapterProvider, IAdapterProvider {

    func adapter() throws -> IAdapter {
        try BitcoinCashAdapter(wallet: wallet, syncMode: syncMode, testMode: testMode)
    }

}

class DashAdapterProvider: BaseBitcoinAdapterProvider, IAdapterProvider {

    func adapter() throws -> IAdapter {
        try DashAdapter(wallet: wallet, syncMode: syncMode, testMode: testMode)
    }

}

class ZcashAdapterProvider: BaseAdapterProvider, IAdapterProvider {
    private let appConfigProvider: IAppConfigProvider
    private let restoreSettingsManager: RestoreSettingsManager

    init(wallet: Wallet, appConfigProvider: IAppConfigProvider, restoreSettingsManager: RestoreSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.restoreSettingsManager = restoreSettingsManager

        super.init(wallet: wallet)
    }

    func adapter() throws -> IAdapter {
        let restoreSettings = restoreSettingsManager.settings(account: wallet.account, coinType: wallet.coin.type)
        return try ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings, testMode: appConfigProvider.testMode)
    }

}

class BaseEvmAdapterProvider: BaseAdapterProvider {
    fileprivate let evmKitManager: EvmKitManager

    init(wallet: Wallet, evmKitManager: EvmKitManager) {
        self.evmKitManager = evmKitManager

        super.init(wallet: wallet)

        subscribe(disposeBag, evmKitManager.evmKitUpdatedObservable) { [weak self] in self?.adapterInvalidatedRelay.accept(()) }
    }

    func evmKit() throws -> EthereumKit.Kit {
        try evmKitManager.evmKit(account: wallet.account)
    }

}

class EvmAdapterProvider: BaseEvmAdapterProvider, IAdapterProvider {

    func adapter() throws -> IAdapter {
        EvmAdapter(evmKit: try evmKit())
    }

}

class Eip20AdapterProvider: BaseEvmAdapterProvider, IAdapterProvider {
    private let contractAddress: String

    init(wallet: Wallet, contractAddress: String, evmKitManager: EvmKitManager) {
        self.contractAddress = contractAddress

        super.init(wallet: wallet, evmKitManager: evmKitManager)
    }

    func adapter() throws -> IAdapter {
        try Evm20Adapter(evmKit: try evmKit(), contractAddress: contractAddress, decimal: wallet.coin.decimal)
    }

}

class BinanceAdapterProvider: BaseAdapterProvider, IAdapterProvider {
    private let symbol: String
    private let binanceKitManager: BinanceKitManager

    init(wallet: Wallet, symbol: String, binanceKitManager: BinanceKitManager) {
        self.symbol = symbol
        self.binanceKitManager = binanceKitManager

        super.init(wallet: wallet)
    }

    func adapter() throws -> IAdapter {
        BinanceAdapter(binanceKit: try binanceKitManager.binanceKit(account: wallet.account), symbol: symbol)
    }

}

class UnsupportedAdapterProvider: IAdapterProvider {

    func adapter() throws -> IAdapter {
        throw AdapterError.wrongParameters
    }

    var adapterInvalidatedObservable: Observable<()> {
        .empty()
    }

}
