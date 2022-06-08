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
        case .alreadyExists(let tokens):
            viewItemRelay.accept(viewItem(tokens: tokens))
        case .fetched(let customCoins):
            viewItemRelay.accept(viewItem(customCoins: customCoins))
        default:
            viewItemRelay.accept(nil)
        }

        if case .fetched = state {
            buttonEnabledRelay.accept(true)
        } else {
            buttonEnabledRelay.accept(false)
        }

        if case .failed(let error) = state {
            cautionRelay.accept(Caution(text: error.convertedError.localizedDescription, type: .error))
        } else if case .alreadyExists = state {
            cautionRelay.accept(Caution(text: "add_token.already_exists".localized, type: .warning))
        } else {
            cautionRelay.accept(nil)
        }
    }

    private func viewItem(tokens: [Token]) -> ViewItem {
        ViewItem(
                protocolTypes: tokens.compactMap { $0.protocolType }.joined(separator: " / "),
                coinName: tokens.first?.coin.name,
                coinCode: tokens.first?.coin.code,
                decimals: tokens.first?.decimals
        )
    }

    private func viewItem(customCoins: [AddTokenModule.CustomCoin]) -> ViewItem {
        ViewItem(
                protocolTypes: customCoins.compactMap { $0.tokenQuery.protocolType }.joined(separator: " / "),
                coinName: customCoins.first?.name,
                coinCode: customCoins.first?.code,
                decimals: customCoins.first?.decimals
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
        let protocolTypes: String
        let coinName: String?
        let coinCode: String?
        let decimals: Int?
    }

}
