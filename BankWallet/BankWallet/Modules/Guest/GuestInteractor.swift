class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let authManager: IAuthManager
    private let wordsManager: IWordsManager

    init(authManager: IAuthManager, wordsManager: IWordsManager) {
        self.authManager = authManager
        self.wordsManager = wordsManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            let words = try wordsManager.generateWords()
            try authManager.login(withWords: words, newWallet: true)

            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
