import RxSwift
import RxRelay
import RxCocoa

class CreateAccountViewModel {
    private let service: CreateAccountService
    private let disposeBag = DisposeBag()

    private let kindRelay = BehaviorRelay<String?>(value: nil)
    private let openSelectKindRelay = PublishRelay<[AlertViewItem]>()
    private let showErrorRelay = PublishRelay<String>()
    private let finishRelay = PublishRelay<()>()

    init(service: CreateAccountService) {
        self.service = service

        subscribe(disposeBag, service.kindObservable) { [weak self] in self?.sync(kind: $0) }

        sync(kind: service.kind)
    }

    private func sync(kind: CreateAccountModule.Kind) {
        kindRelay.accept(kind.title)
    }

}

extension CreateAccountViewModel {

    var kindDriver: Driver<String?> {
        kindRelay.asDriver()
    }

    var openSelectKindSignal: Signal<[AlertViewItem]> {
        openSelectKindRelay.asSignal()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    func onTapKind() {
        let viewItems = service.allKinds.map { type in
            AlertViewItem(text: type.title, selected: type == service.kind)
        }
        openSelectKindRelay.accept(viewItems)
    }

    func onSelectKind(index: Int) {
        service.setKind(index: index)
    }

    func onTapCreate() {
        do {
            try service.createAccount()
            finishRelay.accept(())
        } catch {
            showErrorRelay.accept(error.smartDescription)
        }

    }

}
