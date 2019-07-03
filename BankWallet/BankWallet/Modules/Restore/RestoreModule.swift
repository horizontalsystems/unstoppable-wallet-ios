protocol IRestoreView: class {
    func showSelectType(types: [PredefinedAccountType])
    func showWords(defaultWords: [String])
    func showSyncMode()
    func show(error: Error)
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(type: PredefinedAccountType)
    func didTapRestore(accountType: AccountType)
    func didSelectSyncMode(isFast: Bool)
    func didTapCancel()
}

protocol IRestoreInteractor {
    var defaultWords: [String] { get }
    func validate(words: [String]) throws
    func save(accountType: AccountType, syncMode: SyncMode?)
}

protocol IRestoreInteractorDelegate: class {
}

protocol IRestoreRouter {
    func close()
}
