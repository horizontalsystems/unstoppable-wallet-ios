import RxSwift
import RxRelay
import RxCocoa

class CoinTokensViewModel {
    private let service: CoinTokensService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<BottomMultiSelectorViewController.Config>()

    private var currentRequest: CoinTokensService.Request?

    init(service: CoinTokensService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: CoinTokensService.Request) {
        let fullCoin = request.fullCoin
        let tokens = fullCoin.supportedTokens.sorted

        let config = BottomMultiSelectorViewController.Config(
                icon: .remote(url: fullCoin.coin.imageUrl, placeholder: fullCoin.placeholderImageName),
                title: fullCoin.coin.code,
                description: tokens.count == 1 ? nil : "coin_platforms.description".localized,
                allowEmpty: request.allowEmpty,
                selectedIndexes: request.currentTokens.compactMap { tokens.firstIndex(of: $0) },
                viewItems: tokens.map { token in
                    BottomMultiSelectorViewController.ViewItem(
                            icon: .remote(url: token.blockchain.type.imageUrl, placeholder: nil),
                            title: token.protocolInfo,
                            subtitle: token.typeInfo,
                            copyableString: token.copyableTypeInfo
                    )
                }
        )

        currentRequest = request
        openBottomSelectorRelay.accept(config)
    }

}

extension CoinTokensViewModel {

    var openBottomSelectorSignal: Signal<BottomMultiSelectorViewController.Config> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        guard let request = currentRequest else {
            return
        }

        let supportedTokens = request.fullCoin.supportedTokens.sorted
        service.select(tokens: indexes.map { supportedTokens[$0] }, coin: request.fullCoin.coin)
    }

    func onCancelSelect() {
        guard let request = currentRequest else {
            return
        }

        service.cancel(fullCoin: request.fullCoin)
    }

}
