class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let wordsManager: IWordsManager

    init(wordsManager: IWordsManager) {
        self.wordsManager = wordsManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try wordsManager.createWords()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
