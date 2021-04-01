import RxSwift
import RxRelay
import Darwin

class BackupConfirmKeyService {
    private let account: Account
    private let accountManager: IAccountManager
    private let words: [String]
    private let salt: String?
    private let disposeBag = DisposeBag()

    private let indexItemRelay = PublishRelay<IndexItem>()
    private(set) var indexItem: IndexItem = IndexItem(first: 0, second: 1) {
        didSet {
            indexItemRelay.accept(indexItem)
        }
    }

    init?(account: Account, accountManager: IAccountManager, appManager: IAppManager) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager
        self.words = words
        self.salt = salt

        subscribe(disposeBag, appManager.didBecomeActiveObservable) { [weak self] in self?.generateIndexes() }
    }

    private func generateRandomIndexes(max: Int, count: Int) -> [Int] {
        var indexes = [Int]()

        while indexes.count < count {
            let index = Int(arc4random_uniform(UInt32(max)))
            if !indexes.contains(index) {
                indexes.append(index)
            }
        }

        return indexes
    }

    func validate(word: String, validWord: String) throws {
        guard word.lowercased().trimmingCharacters(in: .whitespaces) == validWord else {
            throw ValidationError.emptyOrInvalidWord
        }
    }

}

extension BackupConfirmKeyService {

    var indexItemObservable: Observable<IndexItem> {
        indexItemRelay.asObservable()
    }

    func generateIndexes() {
        let indexes = generateRandomIndexes(max: words.count, count: 2)
        indexItem = IndexItem(first: indexes[0], second: indexes[1])
    }

    func backup(firstWord: String, secondWord: String) throws {
        try validate(word: firstWord, validWord: words[indexItem.first])
        try validate(word: secondWord, validWord: words[indexItem.second])

        account.backedUp = true
        accountManager.update(account: account)
    }

}

extension BackupConfirmKeyService {

    struct IndexItem {
        let first: Int
        let second: Int
    }

    enum ValidationError: LocalizedError {
        case emptyOrInvalidWord

        var errorDescription: String? {
            switch self {
            case .emptyOrInvalidWord:
                return "backup_key.confirmation.empty_or_invalid_words".localized
            }
        }
    }

}
