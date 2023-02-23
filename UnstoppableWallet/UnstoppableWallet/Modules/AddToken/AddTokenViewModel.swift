import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class AddTokenViewModel {
    private let service: AddTokenService
    private let disposeBag = DisposeBag()

    private let blockchainRelay = BehaviorRelay<String>(value: "")
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let buttonEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let placeholderRelay = BehaviorRelay<String>(value: "")
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let finishRelay = PublishRelay<Void>()

    init(service: AddTokenService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.currentBlockchainItemObservable) { [weak self] in self?.sync(currentBlockchainItem: $0) }

        sync(state: service.state)
        sync(currentBlockchainItem: service.currentBlockchainItem)
    }

    private func sync(currentBlockchainItem: AddTokenService.CurrentBlockchainItem) {
        blockchainRelay.accept(currentBlockchainItem.blockchain.name)
        placeholderRelay.accept(currentBlockchainItem.placeholder)
    }

    private func sync(state: AddTokenService.State) {
        switch state {
        case .idle:
            loadingRelay.accept(false)
            viewItemRelay.accept(nil)
            buttonEnabledRelay.accept(false)
            cautionRelay.accept(nil)
        case .loading:
            loadingRelay.accept(true)
            viewItemRelay.accept(nil)
            buttonEnabledRelay.accept(false)
            cautionRelay.accept(nil)
        case .alreadyExists(let token):
            loadingRelay.accept(false)
            viewItemRelay.accept(viewItem(token: token))
            buttonEnabledRelay.accept(false)
            cautionRelay.accept(Caution(text: "add_token.already_added".localized, type: .warning))
        case .fetched(let token):
            loadingRelay.accept(false)
            viewItemRelay.accept(viewItem(token: token))
            buttonEnabledRelay.accept(true)
            cautionRelay.accept(nil)
        case .failed(let error):
            loadingRelay.accept(false)
            viewItemRelay.accept(nil)
            buttonEnabledRelay.accept(false)
            cautionRelay.accept(Caution(text: error.convertedError.localizedDescription, type: .error))
        }
    }

    private func viewItem(token: Token) -> ViewItem {
        ViewItem(
                name: token.coin.name,
                code: token.coin.code,
                decimals: String(token.decimals)
        )
    }

}

extension AddTokenViewModel {

    var blockchainDriver: Driver<String> {
        blockchainRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var buttonEnabledDriver: Driver<Bool> {
        buttonEnabledRelay.asDriver()
    }

    var placeholderDriver: Driver<String> {
        placeholderRelay.asDriver()
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var blockchainViewItems: [SelectorModule.ViewItem] {
        service.blockchainItems.map { item in
            SelectorModule.ViewItem(
                    image: .url(item.blockchain.type.imageUrl, placeholder: "placeholder_rectangle_32"),
                    title: item.blockchain.name,
                    selected: item.current
            )
        }
    }

    func onSelectBlockchain(index: Int) {
        service.setBlockchain(index: index)
    }

    func onEnter(reference: String?) {
        service.set(reference: reference)
    }

    func onTapButton() {
        service.save()
        finishRelay.accept(())
    }

}

extension AddTokenViewModel {

    struct ViewItem {
        let name: String
        let code: String
        let decimals: String
    }

}
