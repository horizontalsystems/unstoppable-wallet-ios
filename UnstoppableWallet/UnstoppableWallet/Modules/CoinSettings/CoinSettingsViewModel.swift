import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinSettingsViewModel {
    private let service: CoinSettingsService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<BottomMultiSelectorViewController.Config>()

    private var currentRequest: CoinSettingsService.Request?

    init(service: CoinSettingsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinSettingsService.Request) {
        let config: BottomMultiSelectorViewController.Config

        switch request.type {
        case let .derivation(allDerivations, current):
            config = derivationConfig(platformCoin: request.platformCoin, allDerivations: allDerivations, current: current)
        case let .bitcoinCashCoinType(allTypes, current):
            config = bitcoinCashCoinTypeConfig(platformCoin: request.platformCoin, allTypes: allTypes, current: current)
        }

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

    private func derivationConfig(platformCoin: PlatformCoin, allDerivations: [MnemonicDerivation], current: [MnemonicDerivation]) -> BottomMultiSelectorViewController.Config {
        BottomMultiSelectorViewController.Config(
                icon: .remote(iconUrl: platformCoin.coin.imageUrl, placeholder: platformCoin.fullCoin.placeholderImageName),
                title: "blockchain_settings.title".localized,
                subtitle: platformCoin.coin.name,
                description: "blockchain_settings.description".localized,
                selectedIndexes: current.compactMap { allDerivations.firstIndex(of: $0) },
                viewItems: allDerivations.map { derivation in
                    BottomMultiSelectorViewController.ViewItem(
                            title: derivation.title,
                            subtitle: derivation.description
                    )
                }
        )
    }

    private func bitcoinCashCoinTypeConfig(platformCoin: PlatformCoin, allTypes: [BitcoinCashCoinType], current: [BitcoinCashCoinType]) -> BottomMultiSelectorViewController.Config {
        BottomMultiSelectorViewController.Config(
                icon: .remote(iconUrl: platformCoin.coin.imageUrl, placeholder: platformCoin.fullCoin.placeholderImageName),
                title: "blockchain_settings.title".localized,
                subtitle: platformCoin.coin.name,
                description: "blockchain_settings.description".localized,
                selectedIndexes: current.compactMap { allTypes.firstIndex(of: $0) },
                viewItems: allTypes.map { type in
                    BottomMultiSelectorViewController.ViewItem(
                            title: type.title,
                            subtitle: type.description
                    )
                }
        )
    }

}

extension CoinSettingsViewModel {

    var openBottomSelectorSignal: Signal<BottomMultiSelectorViewController.Config> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .derivation(let derivations, _):
            service.select(derivations: indexes.map { derivations[$0] }, platformCoin: request.platformCoin)
        case .bitcoinCashCoinType(let types, _):
            service.select(bitcoinCashCoinTypes: indexes.map { types[$0] }, platformCoin: request.platformCoin)
        }
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(platformCoin: request.platformCoin)
    }

}
