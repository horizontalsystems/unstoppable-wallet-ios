import RxSwift
import RxRelay
import MarketKit

class CoinSettingsService {
    private let approveSettingsRelay = PublishRelay<CoinWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<PlatformCoin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinSettingsService {

    var approveSettingsObservable: Observable<CoinWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<PlatformCoin> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(platformCoin: PlatformCoin, settingsArray: [CoinSettings]) {
        let coinType = platformCoin.coinType

        if coinType.coinSettingTypes.contains(.derivation) {
            let currentDerivations = settingsArray.compactMap { $0[.derivation].flatMap { MnemonicDerivation(rawValue: $0) } }

            let request = Request(
                    platformCoin: platformCoin,
                    type: .derivation(allDerivations: MnemonicDerivation.allCases, current: currentDerivations)
            )

            requestRelay.accept(request)
            return
        }

        if coinType.coinSettingTypes.contains(.bitcoinCashCoinType) {
            let currentTypes = settingsArray.compactMap { $0[.bitcoinCashCoinType].flatMap { BitcoinCashCoinType(rawValue: $0) } }

            let request = Request(
                    platformCoin: platformCoin,
                    type: .bitcoinCashCoinType(allTypes: BitcoinCashCoinType.allCases, current: currentTypes)
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(CoinWithSettings(platformCoin: platformCoin))
    }

    func select(derivations: [MnemonicDerivation], platformCoin: PlatformCoin) {
        let settingsArray: [CoinSettings] = derivations.map { [.derivation: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(platformCoin: platformCoin, settingsArray: settingsArray)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func select(bitcoinCashCoinTypes: [BitcoinCashCoinType], platformCoin: PlatformCoin) {
        let settingsArray: [CoinSettings] = bitcoinCashCoinTypes.map { [.bitcoinCashCoinType: $0.rawValue] }
        let coinWithSettings = CoinWithSettings(platformCoin: platformCoin, settingsArray: settingsArray)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func cancel(platformCoin: PlatformCoin) {
        rejectApproveSettingsRelay.accept(platformCoin)
    }

}

extension CoinSettingsService {

    struct CoinWithSettings {
        let platformCoin: PlatformCoin
        let settingsArray: [CoinSettings]

        init(platformCoin: PlatformCoin, settingsArray: [CoinSettings] = []) {
            self.platformCoin = platformCoin
            self.settingsArray = settingsArray
        }
    }

    struct Request {
        let platformCoin: PlatformCoin
        let type: RequestType
    }

    enum RequestType {
        case derivation(allDerivations: [MnemonicDerivation], current: [MnemonicDerivation])
        case bitcoinCashCoinType(allTypes: [BitcoinCashCoinType], current: [BitcoinCashCoinType])
    }

}
