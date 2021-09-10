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
        case .alreadyExists(let platformCoin):
            viewItemRelay.accept(viewItem(platformCoin: platformCoin))
        case .fetched(let customToken):
            viewItemRelay.accept(viewItem(customToken: customToken))
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

    private func viewItem(platformCoin: PlatformCoin) -> ViewItem {
        ViewItem(
                coinType: platformCoin.coinType.blockchainType,
                coinName: platformCoin.name,
                coinCode: platformCoin.code,
                decimal: platformCoin.decimal
        )
    }

    private func viewItem(customToken: CustomToken) -> ViewItem {
        ViewItem(
                coinType: customToken.coinType.blockchainType,
                coinName: customToken.coinName,
                coinCode: customToken.coinCode,
                decimal: customToken.decimal
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
        service.save()
        finishRelay.accept(())
    }

}

extension AddTokenViewModel {

    struct ViewItem {
        let coinType: String?
        let coinName: String
        let coinCode: String
        let decimal: Int
    }

}
