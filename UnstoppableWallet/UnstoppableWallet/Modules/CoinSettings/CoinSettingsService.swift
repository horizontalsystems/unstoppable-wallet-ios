import RxSwift
import RxRelay
import CoinKit

class CoinSettingsService {
    private let approveSettingsRelay = PublishRelay<CoinWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinSettingsService {

    var approveSettingsObservable: Observable<CoinWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<Coin> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(coin: Coin, settingsArray: [CoinSettings]) {
        if coin.type.coinSettingTypes.contains(.derivation) {
            let currentDerivations = settingsArray.compactMap { $0[.derivation].flatMap { MnemonicDerivation(rawValue: $0) } }

            let request = Request(
                    coin: coin,
                    type: .derivation(allDerivations: MnemonicDerivation.allCases, current: currentDerivations)
            )

            requestRelay.accept(request)
            return
        }

        if coin.type.coinSettingTypes.contains(.bitcoinCashCoinType) {
            let currentTypes = settingsArray.compactMap { $0[.bitcoinCashCoinType].flatMap { BitcoinCashCoinType(rawValue: $0) } }

            let request = Request(
                    coin: coin,
                    type: .bitcoinCashCoinType(allTypes: BitcoinCashCoinType.allCases, current: currentTypes)
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(CoinWithSettings(coin: coin))
    }

    func select(derivations: [MnemonicDerivation], coin: Coin) {
        let settingsArray: [CoinSettings] = derivations.map { [.derivation: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(coin: coin, settingsArray: settingsArray)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func select(bitcoinCashCoinTypes: [BitcoinCashCoinType], coin: Coin) {
        let settingsArray: [CoinSettings] = bitcoinCashCoinTypes.map { [.bitcoinCashCoinType: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(coin: coin, settingsArray: settingsArray)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func cancel(coin: Coin) {
        rejectApproveSettingsRelay.accept(coin)
    }

}

extension CoinSettingsService {

    struct CoinWithSettings {
        let coin: Coin
        let settingsArray: [CoinSettings]

        init(coin: Coin, settingsArray: [CoinSettings] = []) {
            self.coin = coin
            self.settingsArray = settingsArray
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
