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

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
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
        case .fetched(let items, let addedItems):
            viewItemRelay.accept(viewItem(items: items, addedItems: addedItems))

            if items.isEmpty {
                buttonTitleRelay.accept("add_token.already_added".localized)
                buttonEnabledRelay.accept(false)
            } else {
                let hasEnabledItem = items.contains { $0.enabled }
                buttonTitleRelay.accept(hasEnabledItem ? "button.add".localized : "add_token.choose_token".localized)
                buttonEnabledRelay.accept(hasEnabledItem)
            }
        default:
            viewItemRelay.accept(nil)
            buttonTitleRelay.accept("button.add".localized)
            buttonEnabledRelay.accept(false)
        }

        switch state {
        case .failed(let error):
            cautionRelay.accept(Caution(text: error.convertedError.localizedDescription, type: .error))
        case .bep2NotSupported:
            cautionRelay.accept(Caution(text: "add_token.bep2_not_supported".localized, type: .warning))
        default:
            cautionRelay.accept(nil)
        }
    }

    private func viewItem(items: [AddTokenService.Item], addedItems: [AddTokenService.Item]) -> ViewItem {
        ViewItem(
                tokenViewItems: items.map {
                    tokenViewItem(item: $0)
                },
                addedTokenViewItems: addedItems.map {
                    tokenViewItem(item: $0)
                }
        )
    }

    private func tokenViewItem(item: AddTokenService.Item) -> TokenViewItem {
        TokenViewItem(
                imageUrl: item.token.coin.imageUrl,
                placeholderImageName: item.token.placeholderImageName,
                coinCode: item.token.coin.code,
                coinName: item.token.coin.name,
                protocolInfo: item.token.protocolInfo.uppercased(),
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
        let tokenViewItems: [TokenViewItem]
        let addedTokenViewItems: [TokenViewItem]
    }

    struct TokenViewItem {
        let imageUrl: String
        let placeholderImageName: String
        let coinCode: String
        let coinName: String
        let protocolInfo: String
        let isOn: Bool
    }

}
