import Combine

class BlockchainTokensViewModel {
    private let service: BlockchainTokensService
    private var cancellables = Set<AnyCancellable>()

    private let openBottomSelectorSubject = PassthroughSubject<SelectorModule.MultiConfig, Never>()

    init(service: BlockchainTokensService) {
        self.service = service

        service.requestPublisher
            .sink { [weak self] in self?.handle(request: $0) }
            .store(in: &cancellables)
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
            },
            footer: "blockchain_settings.footer".localized
        )

        openBottomSelectorSubject.send(config)
    }
}

extension BlockchainTokensViewModel {
    var openBottomSelectorPublisher: AnyPublisher<SelectorModule.MultiConfig, Never> {
        openBottomSelectorSubject.eraseToAnyPublisher()
    }

    func onSelect(indexes: [Int]) {
        service.select(indexes: indexes)
    }

    func onCancelSelect() {
        service.cancel()
    }
}
