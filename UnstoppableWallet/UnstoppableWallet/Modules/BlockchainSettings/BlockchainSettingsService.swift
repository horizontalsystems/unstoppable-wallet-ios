import RxSwift
import RxRelay

class BlockchainSettingsService {
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    private let approveEnableCoinRelay = PublishRelay<Coin>()
    private let rejectEnableCoinRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()

    init(derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager) {
        self.derivationSettingsManager = derivationSettingsManager
        self.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager
    }

}

extension BlockchainSettingsService {

    var approveEnableCoinObservable: Observable<Coin> {
        approveEnableCoinRelay.asObservable()
    }

    var rejectEnableCoinObservable: Observable<Coin> {
        rejectEnableCoinRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveEnable(coin: Coin, accountOrigin: AccountOrigin) {
        if accountOrigin == .restored, let setting = derivationSettingsManager.setting(coinType: coin.type) {
            let request = Request(
                    coin: coin,
                    type: .derivation(derivations: MnemonicDerivation.allCases, current: setting.derivation)
            )

            requestRelay.accept(request)
            return
        }

        if accountOrigin == .restored, case .bitcoinCash = coin.type {
            let request = Request(
                    coin: coin,
                    type: .bitcoinCashCoinType(types: BitcoinCashCoinType.allCases, current: bitcoinCashCoinTypeManager.bitcoinCashCoinType)
            )

            requestRelay.accept(request)
            return
        }

        approveEnableCoinRelay.accept(coin)
    }

    func select(derivation: MnemonicDerivation, coin: Coin) {
        let setting = DerivationSetting(coinType: coin.type, derivation: derivation)
        derivationSettingsManager.save(setting: setting)

        approveEnableCoinRelay.accept(coin)
    }

    func select(bitcoinCashCoinType: BitcoinCashCoinType, coin: Coin) {
        bitcoinCashCoinTypeManager.save(bitcoinCashCoinType: bitcoinCashCoinType)

        approveEnableCoinRelay.accept(coin)
    }

    func cancel(coin: Coin) {
        rejectEnableCoinRelay.accept(coin)
    }

}

extension BlockchainSettingsService {

    struct Request {
        let coin: Coin
        let type: RequestType
    }

    enum RequestType {
        case derivation(derivations: [MnemonicDerivation], current: MnemonicDerivation)
        case bitcoinCashCoinType(types: [BitcoinCashCoinType], current: BitcoinCashCoinType)
    }

}
