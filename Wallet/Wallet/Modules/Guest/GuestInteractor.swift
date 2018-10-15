class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let wordsManager: IWordsManager

    init(walletManager: IWordsManager) {
        self.wordsManager = walletManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try wordsManager.createWords()
            App.shared.initLoggedInState()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
