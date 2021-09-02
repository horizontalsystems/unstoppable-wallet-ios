import RxSwift
import RxRelay
import RxCocoa
import CoinKit

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
        let marketCoin = request.marketCoin

        let config = BottomMultiSelectorViewController.Config(
//                icon: .image(coinType: marketCoin.platforms),
                icon: nil,
                iconTint: nil,
//                title: "platform_settings.title".localized,
                title: "Coin Type",
                subtitle: marketCoin.coin.name,
//                description: "platform_settings.description".localized(marketCoin.coin.name),
                description: "This token exists on multiple blockchains. Select types you would like to use.",
                selectedIndexes: request.currentPlatforms.compactMap { marketCoin.platforms.firstIndex(of: $0) },
                viewItems: marketCoin.platforms.map { platform in
                    BottomMultiSelectorViewController.ViewItem(
                            title: platform.coinType.platformType,
                            subtitle: platform.coinType.platformCoinType
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

        let platforms = request.marketCoin.platforms

        service.select(platforms: indexes.map { platforms[$0] }, coin: request.marketCoin.coin)
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(coin: request.marketCoin.coin)
    }

}
