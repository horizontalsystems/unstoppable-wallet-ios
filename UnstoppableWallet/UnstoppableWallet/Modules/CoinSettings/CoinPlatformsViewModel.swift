import RxSwift
import RxRelay
import RxCocoa

class CoinPlatformsViewModel {
    private let service: CoinPlatformsService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<BottomMultiSelectorViewController.Config>()

    private var currentRequest: CoinPlatformsService.Request?

    init(service: CoinPlatformsService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinPlatformsService.Request) {
        let fullCoin = request.fullCoin
        let platforms = fullCoin.supportedPlatforms.sorted

        let config = BottomMultiSelectorViewController.Config(
                icon: .remote(iconUrl: fullCoin.coin.imageUrl, placeholder: fullCoin.placeholderImageName),
                title: "coin_platforms.title".localized,
                subtitle: fullCoin.coin.name,
                description: "coin_platforms.description".localized,
                selectedIndexes: request.currentPlatforms.compactMap { platforms.firstIndex(of: $0) },
                viewItems: platforms.map { $0.coinType }.map { coinType in
                    BottomMultiSelectorViewController.ViewItem(
                            iconName: coinType.platformIcon,
                            title: coinType.platformType,
                            subtitle: coinType.platformCoinType
                    )
                }
        )

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

}

extension CoinPlatformsViewModel {

    var openBottomSelectorSignal: Signal<BottomMultiSelectorViewController.Config> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        let supportedPlatforms = request.fullCoin.supportedPlatforms.sorted
        service.select(platforms: indexes.map { supportedPlatforms[$0] }, coin: request.fullCoin.coin)
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(fullCoin: request.fullCoin)
    }

}
