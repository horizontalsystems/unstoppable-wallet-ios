import Combine
import Foundation

class BackupVerifyWordsViewModel: ObservableObject {
    private let account: Account
    private let accountManager: AccountManager
    private var session: BackupVerifyWordsSession
    private var cancellables = Set<AnyCancellable>()
    private let successSubject = PassthroughSubject<Void, Never>()

    @Published private(set) var inputViewItems: [InputViewItem] = []
    @Published private(set) var wordViewItems: [WordViewItem] = []

    init(account: Account, accountManager: AccountManager = Core.shared.accountManager, appManager: AppManager = Core.shared.appManager) {
        self.account = account
        self.accountManager = accountManager

        let words: [String]

        switch account.type {
        case let .mnemonic(accountWords, _, _): words = accountWords
        case let .moneroMnemonic(accountWords, _): words = accountWords
        default: words = []
        }

        session = BackupVerifyWordsSession(words: words)

        appManager.didBecomeActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.reset() }
            .store(in: &cancellables)

        sync()
    }

    private func sync() {
        inputViewItems = session.inputItems.map { item in
            InputViewItem(
                id: item.index,
                text: "\(item.index)." + (item.text.map { " \($0)" } ?? ""),
                selected: item.current
            )
        }

        wordViewItems = session.wordItems.enumerated().map { index, item in
            WordViewItem(id: index, text: item.text, enabled: item.enabled)
        }
    }
}

extension BackupVerifyWordsViewModel {
    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onSelectWord(index: Int) {
        switch session.select(suggestionIndex: index) {
        case .correct:
            sync()
        case .incorrect:
            sync()
            HudHelper.instance.show(banner: .error(string: "backup_verify_words.incorrect_word".localized))
        case .completed:
            sync()
            account.backedUp = true
            accountManager.update(account: account)
            HudHelper.instance.show(banner: .success(string: "backup.verified".localized))
            successSubject.send()
        }
    }

    func reset() {
        session.reset()
        sync()
    }
}

extension BackupVerifyWordsViewModel {
    struct InputViewItem: Identifiable {
        let id: Int
        let text: String
        let selected: Bool
    }

    struct WordViewItem: Identifiable {
        let id: Int
        let text: String
        let enabled: Bool
    }
}
