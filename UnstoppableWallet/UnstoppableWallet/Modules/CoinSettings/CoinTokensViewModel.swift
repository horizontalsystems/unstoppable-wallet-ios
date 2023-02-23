import RxSwift
import RxRelay
import RxCocoa

class CoinTokensViewModel {
    private let service: CoinTokensService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<SelectorModule.MultiConfig>()

    private var currentRequest: CoinTokensService.Request?

    init(service: CoinTokensService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinTokensService.Request) {
        let coin = request.coin
        let tokens = request.eligibleTokens

        let config = SelectorModule.MultiConfig(
                image: .remote(url: coin.imageUrl, placeholder: "placeholder_circle_32"),
                title: coin.code,
                description: tokens.count == 1 ? nil : "coin_platforms.description".localized,
                allowEmpty: request.allowEmpty,
                viewItems: tokens.map { token in
                    SelectorModule.ViewItem(
                            image: .url(token.blockchain.type.imageUrl, placeholder: "placeholder_rectangle_32"),
                            title: token.tokenBlockchain,
                            subtitle: token.typeInfo,
                            selected: request.currentTokens.contains(token)
                    )
                }
        )

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

}

extension CoinTokensViewModel {

    var openBottomSelectorSignal: Signal<SelectorModule.MultiConfig> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        service.select(tokens: indexes.map { request.eligibleTokens[$0] }, coin: request.coin)
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(coin: request.coin)
    }

}
