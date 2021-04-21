import RxSwift
import RxRelay
import Darwin

class BackupConfirmKeyService {
    private let account: Account
    private let accountManager: IAccountManager
    private let words: [String]
    private let salt: String
    private let disposeBag = DisposeBag()

    var firstWord: String = ""
    var secondWord: String = ""
    var passphrase: String = ""

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

    private func validate() -> [ValidationError] {
        var errors = [ValidationError]()

        let firstWord = self.firstWord.lowercased().trimmingCharacters(in: .whitespaces)

        if firstWord.isEmpty {
            errors.append(.emptyFirstWord)
        } else if firstWord != words[indexItem.first] {
            errors.append(.invalidFirstWord)
        }

        let secondWord = self.secondWord.lowercased().trimmingCharacters(in: .whitespaces)

        if secondWord.isEmpty {
            errors.append(.emptySecondWord)
        } else if secondWord != words[indexItem.second] {
            errors.append(.invalidSecondWord)
        }

        if !salt.isEmpty {
            if passphrase.isEmpty {
                errors.append(.emptyPassphrase)
            } else if passphrase != salt {
                errors.append(.invalidPassphrase)
            }
        }

        return errors
    }

}

extension BackupConfirmKeyService {

    var indexItemObservable: Observable<IndexItem> {
        indexItemRelay.asObservable()
    }

    var hasSalt: Bool {
        !salt.isEmpty
    }

    func generateIndexes() {
        let indexes = generateRandomIndexes(max: words.count, count: 2)
        indexItem = IndexItem(first: indexes[0], second: indexes[1])
    }

    func backup() throws {
        let validationErrors = validate()

        guard validationErrors.isEmpty else {
            throw BackupError(validationErrors: validationErrors)
        }

        account.backedUp = true
        accountManager.update(account: account)
    }

}

extension BackupConfirmKeyService {

    struct IndexItem {
        let first: Int
        let second: Int
    }

    struct BackupError: Error {
        let validationErrors: [ValidationError]
    }

    enum ValidationError: Error {
        case emptyFirstWord
        case invalidFirstWord
        case emptySecondWord
        case invalidSecondWord
        case emptyPassphrase
        case invalidPassphrase
    }

}
