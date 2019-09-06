import RxSwift

class BackupConfirmationInteractor: IBackupConfirmationInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IBackupConfirmationInteractorDelegate?

    private let randomManager: IRandomManager
    private let wordsValidator: WordsValidator

    private let async: Bool

    init(randomManager: IRandomManager, wordsValidator: WordsValidator, appManager: IAppManager, async: Bool = true) {
        self.randomManager = randomManager
        self.wordsValidator = wordsValidator

        self.async = async

        appManager.didBecomeActiveObservable
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.onBecomeActive()
                })
                .disposed(by: disposeBag)
    }

    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int] {
        return randomManager.getRandomIndexes(max: max, count: count)
    }

    func validate(words: [String], confirmationIndexes: [Int], confirmationWords: [String]) throws {
        try wordsValidator.validate(words: words, confirmationIndexes: confirmationIndexes, confirmationWords: confirmationWords)
    }

}
