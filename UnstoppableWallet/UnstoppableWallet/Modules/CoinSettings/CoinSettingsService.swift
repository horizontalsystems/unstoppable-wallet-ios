import RxSwift
import RxRelay
import CoinKit

class CoinSettingsService {
    private let approveEnableCoinRelay = PublishRelay<CoinWithSettings>()
    private let rejectEnableCoinRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinSettingsService {

    var approveEnableCoinObservable: Observable<CoinWithSettings> {
        approveEnableCoinRelay.asObservable()
    }

    var rejectEnableCoinObservable: Observable<Coin> {
        rejectEnableCoinRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveEnable(coin: Coin, settingsData: [[CoinSetting: String]]) {
        if coin.type.coinSettings.contains(.derivation) {
            let currentDerivations = settingsData.compactMap { $0[.derivation].flatMap { MnemonicDerivation(rawValue: $0) } }

            let request = Request(
                    coin: coin,
                    type: .derivation(allDerivations: MnemonicDerivation.allCases, current: currentDerivations)
            )

            requestRelay.accept(request)
            return
        }

        if coin.type.coinSettings.contains(.bitcoinCashCoinType) {
            let currentTypes = settingsData.compactMap { $0[.bitcoinCashCoinType].flatMap { BitcoinCashCoinType(rawValue: $0) } }

            let request = Request(
                    coin: coin,
                    type: .bitcoinCashCoinType(allTypes: BitcoinCashCoinType.allCases, current: currentTypes)
            )

            requestRelay.accept(request)
            return
        }

        approveEnableCoinRelay.accept(CoinWithSettings(coin: coin))
    }

    func select(derivations: [MnemonicDerivation], coin: Coin) {
        let settingsData: [[CoinSetting: String]] = derivations.map { [.derivation: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(coin: coin, settingsData: settingsData)
        approveEnableCoinRelay.accept(coinWithSettings)
    }

    func select(bitcoinCashCoinTypes: [BitcoinCashCoinType], coin: Coin) {
        let settingsData: [[CoinSetting: String]] = bitcoinCashCoinTypes.map { [.bitcoinCashCoinType: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(coin: coin, settingsData: settingsData)
        approveEnableCoinRelay.accept(coinWithSettings)
    }

    func cancel(coin: Coin) {
        rejectEnableCoinRelay.accept(coin)
    }

}

extension CoinSettingsService {

    struct CoinWithSettings {
        let coin: Coin
        let settingsData: [[CoinSetting: String]]

        init(coin: Coin, settingsData: [[CoinSetting: String]] = []) {
            self.coin = coin
            self.settingsData = settingsData
        }
    }

    struct Request {
        let coin: Coin
        let type: RequestType
    }

    enum RequestType {
        case derivation(allDerivations: [MnemonicDerivation], current: [MnemonicDerivation])
        case bitcoinCashCoinType(allTypes: [BitcoinCashCoinType], current: [BitcoinCashCoinType])
    }

}
