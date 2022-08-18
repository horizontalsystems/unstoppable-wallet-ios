import RxSwift
import RxRelay
import RxCocoa

class BackupVerifyWordsViewModel {
    private let service: BackupVerifyWordsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(inputViewItems: [], wordViewItems: []))
    private let errorRelay = PublishRelay<String>()
    private let openPassphraseRelay = PublishRelay<Account>()
    private let successRelay = PublishRelay<()>()

    init(service: BackupVerifyWordsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: BackupVerifyWordsService.State) {
        let viewItem = ViewItem(
                inputViewItems: state.inputItems.map { item in
                    InputViewItem(
                            text: "\(item.index)." + (item.text.map { " \($0)" } ?? ""),
                            selected: item.current
                    )
                },
                wordViewItems: state.wordItems.map { item in
                    WordViewItem(
                            text: item.text,
                            enabled: item.enabled
                    )
                }
        )

        viewItemRelay.accept(viewItem)
    }

}

extension BackupVerifyWordsViewModel {

    var viewItemDriver: Driver<ViewItem> {
        viewItemRelay.asDriver()
    }

    var errorSignal: Signal<String> {
        errorRelay.asSignal()
    }

    var openPassphraseSignal: Signal<Account> {
        openPassphraseRelay.asSignal()
    }

    var successSignal: Signal<()> {
        successRelay.asSignal()
    }

    func onViewAppear() {
        service.reset()
    }

    func onSelectWord(index: Int) {
        let result = service.handleSelectedWord(index: index)

        switch result {
        case .correct: ()
        case .incorrect: errorRelay.accept("backup_verify_words.incorrect_word".localized)
        case .showPassphrase: openPassphraseRelay.accept(service.account)
        case .backedUp: successRelay.accept(())
        }
    }

}

extension BackupVerifyWordsViewModel {

    struct ViewItem {
        let inputViewItems: [InputViewItem]
        let wordViewItems: [WordViewItem]
    }

    struct InputViewItem {
        let text: String
        let selected: Bool
    }

    struct WordViewItem {
        let text: String
        let enabled: Bool
    }

}
