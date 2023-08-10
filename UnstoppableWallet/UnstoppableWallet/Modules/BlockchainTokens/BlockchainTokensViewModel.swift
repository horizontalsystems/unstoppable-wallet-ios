import RxSwift
import RxRelay
import RxCocoa

class BlockchainTokensViewModel {
    private let service: BlockchainTokensService
    private let disposeBag = DisposeBag()

    private let openBottomSelectorRelay = PublishRelay<SelectorModule.MultiConfig>()

    init(service: BlockchainTokensService) {
        self.service = service

        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.handle(request: $0) }
    }

    private func handle(request: BlockchainTokensService.Request) {
        let blockchain = request.blockchain

        let config = SelectorModule.MultiConfig(
                image: .remote(url: blockchain.type.imageUrl, placeholder: "placeholder_rectangle_32"),
                title: blockchain.name,
                description: "blockchain_settings.description".localized,
                allowEmpty: request.allowEmpty,
                viewItems: request.tokens.map { token in
                    SelectorModule.ViewItem(
                            title: token.type.title,
                            subtitle: token.type.description,
                            selected: request.enabledTokens.contains(token)
                    )
                }
        )

        openBottomSelectorRelay.accept(config)
    }

}

extension BlockchainTokensViewModel {

    var openBottomSelectorSignal: Signal<SelectorModule.MultiConfig> {
        openBottomSelectorRelay.asSignal()
    }

    func onSelect(indexes: [Int]) {
        service.select(indexes: indexes)
    }

    func onCancelSelect() {
        service.cancel()
    }

}
