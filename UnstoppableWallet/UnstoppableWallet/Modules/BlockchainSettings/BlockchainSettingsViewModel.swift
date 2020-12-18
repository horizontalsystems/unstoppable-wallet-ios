import RxSwift
import RxRelay
import RxCocoa

class BlockchainSettingsViewModel {
    private let service: BlockchainSettingsService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<BottomSelectorViewController.Config>()

    private var currentRequest: BlockchainSettingsService.Request?

    init(service: BlockchainSettingsService) {
        self.service = service

        service.requestObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] request in
                    self?.handle(request: request)
                })
                .disposed(by: disposeBag)
    }

    private func handle(request: BlockchainSettingsService.Request) {
        let config: BottomSelectorViewController.Config

        switch request.type {
        case .derivation(let derivations, let current):
            config = derivationConfig(coin: request.coin, derivations: derivations, current: current)
        case .bitcoinCashCoinType(let types, let current):
            config = bitcoinCashCoinTypeConfig(coin: request.coin, types: types, current: current)
        }

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

    private func derivationConfig(coin: Coin, derivations: [MnemonicDerivation], current: MnemonicDerivation) -> BottomSelectorViewController.Config {
        BottomSelectorViewController.Config(
                icon: .image(coinCode: coin.code, blockchainType: coin.type.blockchainType),
                title: "blockchain_settings.title".localized,
                subtitle: coin.title,
                selectedIndex: derivations.firstIndex(of: current) ?? 0,
                viewItems: derivations.map { derivation in
                    BottomSelectorViewController.ViewItem(
                            title: derivation.title,
                            subtitle: derivation.description(coinType: coin.type)
                    )
                }
        )
    }

    private func bitcoinCashCoinTypeConfig(coin: Coin, types: [BitcoinCashCoinType], current: BitcoinCashCoinType) -> BottomSelectorViewController.Config {
        BottomSelectorViewController.Config(
                icon: .image(coinCode: coin.code, blockchainType: coin.type.blockchainType),
                title: "blockchain_settings.title".localized,
                subtitle: coin.title,
                selectedIndex: types.firstIndex(of: current) ?? 0,
                viewItems: types.map { type in
                    BottomSelectorViewController.ViewItem(
                            title: type.title,
                            subtitle: type.description
                    )
                }
        )
    }

}

extension BlockchainSettingsViewModel {

    var openBottomSelectorSignal: Signal<BottomSelectorViewController.Config> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(index: Int) {
        guard let request = currentRequest else {
            return
        }

        switch request.type {
        case .derivation(let derivations, _):
            service.select(derivation: derivations[index], coin: request.coin)
        case .bitcoinCashCoinType(let types, _):
            service.select(bitcoinCashCoinType: types[index], coin: request.coin)
        }
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(coin: request.coin)
    }

}
