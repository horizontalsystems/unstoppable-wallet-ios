import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class AddTokenViewModel {
    private let service: AddTokenService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
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
        case .fetched(let items):
            viewItemRelay.accept(viewItem(items: items))

            let hasEnabledItem = items.contains(where: {
                switch $0.state {
                case .enabled: return true
                default: return false
                }
            })

            buttonEnabledRelay.accept(hasEnabledItem)
        default:
            viewItemRelay.accept(nil)
            buttonEnabledRelay.accept(false)
        }

        if case .failed(let error) = state {
            cautionRelay.accept(Caution(text: error.convertedError.localizedDescription, type: .error))
        } else {
            cautionRelay.accept(nil)
        }
    }

    private func viewItem(items: [AddTokenService.Item]) -> ViewItem {
        ViewItem(
                coinName: items.first?.token.coin.name,
                coinCode: items.first?.token.coin.code,
                decimals: items.first.map { String($0.token.decimals) },
                tokenViewItems: items.map {
                    tokenViewItem(item: $0)
                }
        )
    }

    private func tokenViewItem(item: AddTokenService.Item) -> TokenViewItem {
        let enabled: Bool
        let isOn: Bool

        switch item.state {
        case .alreadyEnabled:
            enabled = false
            isOn = true
        case .enabled:
            enabled = true
            isOn = true
        case .disabled:
            enabled = true
            isOn = false
        }

        return TokenViewItem(
                imageUrl: item.token.blockchain.type.imageUrl,
                title: item.token.protocolName,
                enabled: enabled,
                isOn: isOn
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

    func onToggleToken(index: Int, isOn: Bool) {
        service.toggleToken(index: index, isOn: isOn)
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
        let tokenViewItems: [TokenViewItem]
    }

    struct TokenViewItem {
        let imageUrl: String
        let title: String?
        let enabled: Bool
        let isOn: Bool
    }

}
