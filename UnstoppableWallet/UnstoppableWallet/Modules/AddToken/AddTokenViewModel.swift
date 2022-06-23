import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class AddTokenViewModel {
    private let service: AddTokenService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let buttonTitleRelay = BehaviorRelay<String?>(value: nil)
    private let buttonEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let finishRelay = PublishRelay<Void>()

    init(service: AddTokenService) {
        self.service = service

        service.stateObservable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.sync(state: state)
                })
                .disposed(by: disposeBag)

        sync(state: service.state)
    }

    private func sync(state: AddTokenService.State) {
        if case .loading = state {
            loadingRelay.accept(true)
        } else {
            loadingRelay.accept(false)
        }

        switch state {
        case .fetched(let addedItems, let items):
            viewItemRelay.accept(viewItem(addedItems: addedItems, items: items))

            if items.isEmpty {
                buttonTitleRelay.accept("add_token.already_added".localized)
                buttonEnabledRelay.accept(false)
            } else {
                let hasEnabledItem = items.contains { $0.enabled }
                buttonTitleRelay.accept(hasEnabledItem ? "button.add".localized : "add_token.choose_type".localized)
                buttonEnabledRelay.accept(hasEnabledItem)
            }
        default:
            viewItemRelay.accept(nil)
            buttonTitleRelay.accept("button.add".localized)
            buttonEnabledRelay.accept(false)
        }

        if case .failed(let error) = state {
            cautionRelay.accept(Caution(text: error.convertedError.localizedDescription, type: .error))
        } else {
            cautionRelay.accept(nil)
        }
    }

    private func viewItem(addedItems: [AddTokenService.Item], items: [AddTokenService.Item]) -> ViewItem {
        let item = addedItems.first ?? items.first

        return ViewItem(
                coinName: item?.token.coin.name,
                coinCode: item?.token.coin.code,
                decimals: item.map { String($0.token.decimals) },
                addedTokenViewItems: addedItems.map { tokenViewItem(item: $0) },
                tokenViewItems: items.map { tokenViewItem(item: $0) }
        )
    }

    private func tokenViewItem(item: AddTokenService.Item) -> TokenViewItem {
        TokenViewItem(
                imageUrl: item.token.blockchain.type.imageUrl,
                title: item.token.protocolName,
                isOn: item.enabled
        )
    }

}

extension AddTokenViewModel {

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var buttonTitleDriver: Driver<String?> {
        buttonTitleRelay.asDriver()
    }

    var buttonEnabledDriver: Driver<Bool> {
        buttonEnabledRelay.asDriver()
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onEnter(reference: String?) {
        service.set(reference: reference)
    }

    func onToggleToken(index: Int) {
        service.toggleToken(index: index)
    }

    func onTapButton() {
        do {
            try service.save()
            finishRelay.accept(())
        } catch {
            // todo
        }
    }

}

extension AddTokenViewModel {

    struct ViewItem {
        let coinName: String?
        let coinCode: String?
        let decimals: String?
        let addedTokenViewItems: [TokenViewItem]
        let tokenViewItems: [TokenViewItem]
    }

    struct TokenViewItem {
        let imageUrl: String
        let title: String?
        let isOn: Bool
    }

}
